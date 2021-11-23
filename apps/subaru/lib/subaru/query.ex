defmodule Subaru.Query do
  alias :queue, as: Queue

  @type literal() :: integer() | bitstring() | atom()
  @type relational_operator() :: :> | :>= | :< | :<= | :== | :!=
  @type truthy() :: :and | :or

  @type conditional() :: {bitstring(), relational_operator(), literal()}
  @type boolean_expression() :: {truthy(), conditional(), conditional()} | conditional()

  def new() do
    Queue.new()
  end

  def for(q, collection) when is_bitstring(collection) do
    statement = {:for, collection}
    Queue.in(statement, q)
  end

  @spec filter(:queue.queue(), boolean_expression()) :: :queue.queue()
  def filter(q, expr) do
    statement = {:filter, expr}
    Queue.in(statement, q)
  end

  def exec(q) do
    {item, tail} = item_tail(q)
    exec(item, tail, [])
  end

  defp exec(:empty, _, acc) do
    acc
  end

  defp exec({:for, collection}, q, acc) do
    statement = "FOR x IN #{collection}"
    {item, queue} = item_tail(q)
    exec(item, queue, [statement | acc])
  end

  defp exec({:filter, expr}, q, acc) do
    statement = reduce_expr(expr)
    {item, queue} = item_tail(q)
    exec(item, queue, [statement | acc])
  end

  # REDUCERS
  @spec reduce_expr(boolean_expression()) :: bitstring()
  defp reduce_expr({var, op, val}) when is_bitstring(var) do
    "#{var} #{op} #{val}"
  end

  # defp reduce_expr({_, p, q}) when is_tuple(p) or is_tuple(q) do

  # end

  defp reduce_expr({truthy, p, q}) do
    # conditional
    #   {bitstr, relational_op, literal}
    # {truthy, conditional, conditional}
    #   {:and, p, q}
    #   {:or, p, q}

    p_red = reduce_expr(p)
    q_red = reduce_expr(q)
    op = truthy_to_str(truthy)

    "(#{p_red} #{op} #{q_red})"
  end

  defp truthy_to_str(:and), do: "&&"
  defp truthy_to_str(:or), do: "||"

  # defp reduce_expr2({:and, p, q}) when not is_tuple(p) and not is_tuple(q) do
  #   "#{p} && #{q}"
  # end

  # UTILITIES
  @spec item_tail(:queue.queue()) :: {any(), :queue.queue()}
  defp item_tail(q) do
    case Queue.out(q) do
      {{:value, item}, tail} ->
        {item, tail}

      otherwise ->
        otherwise
    end
  end
end
