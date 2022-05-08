defmodule Subaru.Query do
  require Logger

  @moduledoc """
  The end goal is to have a stable wrapper for our DB that feels as good to use
    as elixir does, maybe even Mnesia inspired.
  """
  defstruct [:q, :bindvars, :statement, :context, :depth, :writes, :reads]

  alias :queue, as: Queue
  alias __MODULE__

  @type queue() :: Queue.queue()

  @type t() :: %__MODULE__{
          q: queue(),
          bindvars: Map.t(),
          statement: [String.t()],
          context: [atom()],
          depth: integer(),
          writes: MapSet.t(),
          reads: MapSet.t()
        }

  @type literal() :: integer() | bitstring() | atom()
  @type relational_operator() :: :> | :>= | :< | :<= | :== | :!=
  @type truthy() :: :and | :or

  @type conditional() :: {relational_operator(), bitstring(), literal()}
  @type boolean_expression() :: {truthy(), conditional(), conditional()} | conditional()

  @spec new :: Query.t()
  def new() do
    %Query{
      q: Queue.new(),
      bindvars: %{},
      statement: [],
      context: [:root],
      depth: 0,
      writes: MapSet.new(),
      reads: MapSet.new()
    }
  end

  @spec let(Query.t(), atom(), any()) :: Query.t()
  def let(q, variableName, expression) do
    item = {:let, variableName, expression}
    push(q, item)
  end

  @spec for(t, atom(), String.t()) :: t
  def for(q, variableName, collection) do
    item = {:for, variableName, collection}
    push(q, item)
  end

  @spec insert(t, any(), String.t()) :: t
  def insert(q, doc, collection) do
    item = {:insert, doc, collection}
    push(q, item)
  end

  @spec upsert(t, any(), any(), any(), String.t()) :: t
  def upsert(q, searchdoc, insertdoc, updatedoc, collection) do
    item = {:upsert, searchdoc, insertdoc, updatedoc, collection}
    push(q, item)
  end

  def remove(q, variableName, collection) do
    item = {:remove, variableName, collection}
    push(q, item)
  end

  def traverse(q, ecoll, direction, startvert, min, max) do
    item = {:traverse, ecoll, direction, startvert, min, max}
    push(q, item)
  end

  @spec filter(t, boolean_expression()) :: t
  def filter(q, expr) do
    item = {:filter, expr}
    push(q, item)
  end

  def return(q, expr) do
    item = {:return, expr}
    push(q, item)
  end

  def get(q, collection, id) do
    return(q, "DOCUMENT(\"#{collection}/#{id}\")")
  end

  def first(q, return \\ false) when is_boolean(return) do
    item = {:first, return}
    push(q, item)
  end

  def limit(q, amount) when is_integer(amount) do
    item = {:limit, amount}
    push(q, item)
  end

  @spec exec(t) :: Arangox.Response.t()
  def exec(query) do
    {statement, bindvars, opts} = run(query)
    Subaru.DB.exec(statement, bindvars, opts)
  end

  @doc """
  Generate AQL code.
  """
  def run(query) do
    q = gen(query)

    statement = gen_statement(q)
    bindvars = q.bindvars
    opts = [write: MapSet.to_list(q.writes), read: MapSet.to_list(q.reads)]

    # For debug purposes
    maxlinelen =
      statement
      |> String.split("\n")
      |> Enum.map(&String.length/1)
      |> Enum.max()


    logborder = String.duplicate("*", maxlinelen)
    Logger.debug("EXECUTING QUERY:\n#{logborder}\n#{statement}\n#{logborder}")

    {statement, bindvars, opts}
  end

  @doc """
  Generate but don't execute AQL code.
  """
  def gen(query) do
    {q, item} = pop(query)
    gen(item, q)
  end

  defp gen(:empty, query), do: query

  # set var to query result
  defp gen({:let, variableName, %Query{} = expression}, query) do
    subquery = gen(expression)
    [expr_stmnt_head | expr_stmnt_tail] = subquery.statement

    query
    |> merge_bindvars(subquery.bindvars)
    |> merge_rw_colls(subquery.reads, subquery.writes)
    |> add_statement("LET #{variableName} = " <> expr_stmnt_head)
    |> add_statements(expr_stmnt_tail)
    |> gen()
  end

  # set var to literal
  defp gen({:let, variableName, expression}, query) do
    bindvar_id = generate_bindvar(expression)
    statement = "LET #{variableName} = " <> bindvar_id

    query
    |> add_statement(statement)
    |> add_bindvar(bindvar_id, expression)
    |> gen()
  end

  defp gen({:insert, doc, collection}, query) do
    doc_bindvar = generate_bindvar(doc)
    coll_bindvar = "@" <> generate_bindvar(collection)
    statement = "INSERT #{doc_bindvar} INTO #{coll_bindvar} RETURN NEW._id"

    query
    |> add_statement(statement)
    |> add_bindvar(doc_bindvar, doc)
    |> add_bindvar(coll_bindvar, collection)
    |> add_write_coll(collection)
    |> gen()
  end

  defp gen({:upsert, searchdoc, insertdoc, updatedoc, collection}, query) do
    bv_sdoc = generate_bindvar(searchdoc)
    bv_idoc = generate_bindvar(insertdoc)
    bv_udoc = generate_bindvar(updatedoc)
    coll_bindvar = "@" <> generate_bindvar(collection)

    statement =
      "UPSERT #{bv_sdoc} INSERT #{bv_idoc} UPDATE #{bv_udoc} IN #{coll_bindvar} RETURN NEW._id"

    query
    |> add_statement(statement)
    |> add_bindvar(bv_sdoc, searchdoc)
    |> add_bindvar(bv_idoc, insertdoc)
    |> add_bindvar(bv_udoc, updatedoc)
    |> add_bindvar(coll_bindvar, collection)
    |> add_write_coll(collection)
    |> gen()
  end

  defp gen({:remove, variableName, collection}, query) do
    coll_bindvar = "@" <> generate_bindvar(collection)
    statement = "REMOVE #{variableName} IN #{coll_bindvar}"

    query
    |> add_statement(statement)
    |> add_bindvar(coll_bindvar, collection)
    |> add_write_coll(collection)
    |> gen()
  end

  defp gen({:for, variableName, collection}, query) do
    coll_bindvar = "@" <> generate_bindvar(collection)
    statement = "FOR #{variableName} IN #{coll_bindvar}"

    query
    |> add_statement(statement)
    |> add_bindvar(coll_bindvar, collection)
    |> add_read_coll(collection)
    |> gen()
  end

  defp gen({:traverse, ecoll, direction, startvert, min, max}, query) do
    # ecoll_bindvars = Enum.map(ecolls, fn ec -> "@" <> generate_bindvar(ec) end)
    # ecoll_bindvar = "@" <> generate_bindvar(ecoll)
    startvert_bindvar_id = generate_bindvar(startvert)

    stm_min_max =
      if !is_nil(min) and !is_nil(max) do
        " #{min}..#{max}"
      else
        ""
      end

    statement = """
    FOR v IN#{stm_min_max} #{edgedir_to_str(direction)}
        #{startvert_bindvar_id}
        #{ecoll}
        RETURN v
    """

    query
    |> add_statement(statement)
    # |> add_bindvar(ecoll_bindvar, ecoll)
    |> add_bindvar(startvert_bindvar_id, startvert)
    |> add_read_coll(ecoll)
    |> gen()
  end

  defp gen({:filter, expr}, query) do
    statement = "FILTER " <> reduce_expr(expr)

    query
    |> add_statement(statement)
    |> gen()
  end

  defp gen({:return, expr}, query) do
    statement = "RETURN " <> expr

    query
    |> add_statement(statement)
    |> gen()
  end

  # query must be array query starting with FOR
  defp gen({:first, return}, %Query{statement: ["FOR" <> _ | _]} = query) do
    statement_prefix =
      if return do
        "RETURN "
      else
        ""
      end

    statement_start = statement_prefix <> "FIRST("
    statement_close = ")"

    Query.new()
    |> merge_bindvars(query.bindvars)
    |> merge_rw_colls(query.reads, query.writes)
    |> add_statement(statement_start)
    |> add_statements(query.statement)
    |> add_statement(statement_close)
    |> gen()
  end

  defp gen({:limit, amount}, query) do
    statement = "LIMIT #{amount}"

    query
    |> add_statement(statement)
    |> gen()
  end

  # TODO: Temp. Needs indentation stuff a la query.depth, etc.
  @spec gen_statement(t) :: String.t()
  defp gen_statement(query) do
    helper_gen_statement(query, query.statement, "")
  end

  defp helper_gen_statement(_, [], acc), do: acc

  defp helper_gen_statement(query, [h | tail], acc) do
    {depth, context} =
      case h do
        "FOR " <> _ ->
          {query.depth + 1, context_update(query, :for)}

        "RETURN " <> _ ->
          {query.depth - 1, context_update(query, :pop)}

        ")" <> _ ->
          {query.depth - 1, context_update(query, :pop)}

        _ ->
          cond do
            String.ends_with?(h, "FIRST(") ->
              {query.depth + 1, context_update(query, :first)}

            true ->
              {query.depth, query.context}
          end
      end

    acc =
      (acc <> "\n" <> String.duplicate(" ", max(query.depth * 4, 0)) <> h)
      |> String.trim_leading()

    helper_gen_statement(%Query{query | depth: depth, context: context}, tail, acc)
  end

  @spec reduce_expr(boolean_expression()) :: bitstring()
  defp reduce_expr({op, var, val}) when is_bitstring(var) and is_bitstring(val) do
    "#{var} #{op} #{quoted(val)}"
  end

  defp reduce_expr({op, var, val}) when is_number(val) do
    "#{var} #{op} #{val}"
  end

  defp reduce_expr({truthy, p, q}) do
    p_red = reduce_expr(p)
    q_red = reduce_expr(q)
    op = truthy_to_str(truthy)

    "(#{p_red} #{op} #{q_red})"
  end

  @spec push(Query.t(), any()) :: Query.t()
  defp push(query, item) do
    %Query{query | q: Queue.in(item, query.q)}
  end

  @spec add_statement(Query.t(), binary()) :: Query.t()
  defp add_statement(query, statement) do
    add_statements(query, [statement])
  end

  @spec add_statement(Query.t(), [binary()]) :: Query.t()
  defp add_statements(query, statements) do
    %Query{query | statement: query.statement ++ statements}
  end

  @spec add_bindvar(t, bitstring(), any()) :: t
  defp add_bindvar(query, "@" <> key, value) do
    %Query{query | bindvars: Map.put(query.bindvars, key, value)}
  end

  @spec merge_bindvars(t, Map.t()) :: t
  defp merge_bindvars(query, bindvars) do
    %Query{query | bindvars: Map.merge(query.bindvars, bindvars)}
  end

  defp add_write_coll(query, coll) do
    %Query{query | writes: MapSet.put(query.writes, coll)}
  end

  defp add_read_coll(query, coll) do
    %Query{query | reads: MapSet.put(query.reads, coll)}
  end

  @spec add_read_colls(t(), [bitstring()]) :: t()
  defp add_read_colls(query, colls) do
    %Query{query | reads: MapSet.union(query.reads, MapSet.new(colls))}
  end

  defp merge_rw_colls(query, reads, writes) do
    %Query{
      query
      | reads: MapSet.union(query.reads, reads),
        writes: MapSet.union(query.writes, writes)
    }
  end

  @spec pop(Query.t()) :: {Query.t(), any()}
  defp pop(query) do
    case Queue.out(query.q) do
      {{:value, item}, tail} ->
        {%Query{query | q: tail}, item}

      {:empty, _} ->
        {query, :empty}
    end
  end

  defp context_update(%Query{context: [:root]} = query, :pop) do
    query.context
  end

  defp context_update(query, :pop) do
    tl(query.context)
  end

  defp context_update(query, a) when is_atom(a) do
    [a | query.context]
  end

  # primarily used for generating unique ids for hashable objects.
  defp generate_bindvar(var) do
    id = :erlang.phash2(var, 10_000)
    "@var#{id}"
  end

  defp truthy_to_str(:and), do: "&&"
  defp truthy_to_str(:or), do: "||"

  defp edgedir_to_str(:outbound), do: "OUTBOUND"
  defp edgedir_to_str(:inbound), do: "INBOUND"
  defp edgedir_to_str(:any), do: "ANY"

  defp quoted(s) when is_bitstring(s) do
    "\"#{s}\""
  end
end
