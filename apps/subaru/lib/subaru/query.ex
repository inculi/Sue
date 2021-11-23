defmodule Subaru.Query do
  """
  This module is still under construction. I want to eventually have a stable
    wrapper that is more elixiry, maybe even Mnesia inspired.
  I'll put this on hold for now as I want to get more familiar with Arango first
    so I can get an idea of what kind of queries I'll be commonly making.
  """

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

  defp reduce_expr({truthy, p, q}) do
    p_red = reduce_expr(p)
    q_red = reduce_expr(q)
    op = truthy_to_str(truthy)

    "(#{p_red} #{op} #{q_red})"
  end

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

  defp truthy_to_str(:and), do: "&&"
  defp truthy_to_str(:or), do: "||"
end
