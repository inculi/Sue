defmodule Subaru do
  alias Subaru.Query

  # Database Result
  # Arangox.Response.t()
  @type dbres() :: {:ok, list()} | {:error, any()}
  @type res_id() :: {:ok, bitstring()} | {:error, any()}

  @spec upsert(map(), map(), map(), bitstring()) :: res_id()
  def upsert(d_search, d_insert, d_update, collection) do
    Query.new()
    |> Query.upsert(d_search, d_insert, d_update, collection)
    |> Query.exec()
    |> result_id()
  end

  @spec insert(Subaru.Vertex.t()) :: res_id()
  def insert(v) when is_struct(v) do
    insert(Subaru.Vertex.doc(v), Subaru.Vertex.collection(v))
  end

  def insert!(v) do
    {:ok, res} = insert(v)
    res
  end

  @spec insert(map(), bitstring()) :: res_id()
  def insert(doc, collection) when is_map(doc) do
    Query.new()
    |> Query.insert(doc, collection)
    |> Query.exec()
    |> result_id()
  end

  def insert!(doc, collection) do
    {:ok, res} = insert(doc, collection)
    res
  end

  @spec insert_edge(bitstring(), bitstring(), bitstring()) :: res_id()
  def insert_edge(from_id, to_id, edge_collection) do
    Query.new()
    |> Query.insert(%{_from: from_id, _to: to_id}, edge_collection)
    |> Query.exec()
    |> result_id()
  end

  @spec remove_all(bitstring()) :: :ok
  def remove_all(collection) do
    Query.new()
    |> Query.for(:x, collection)
    |> Query.remove(:x, collection)
    |> Query.exec()
    |> result()
  end

  @doc """
  Finds and returns document according to filter.
  """
  @spec find_one(bitstring(), Query.boolean_expression()) :: map()
  def find_one(collection, expr) do
    Query.new()
    |> Query.for(:x, collection)
    |> Query.filter(expr)
    |> Query.limit(1)
    |> Query.return("x")
    |> Query.exec()
    |> result_one()
  end

  def find_one!(collection, expr) do
    {:ok, res} = find_one(collection, expr)
    res
  end

  # RESULT OUTPUT HELPERS
  # =====================

  # @spec result(dbres()) :: [map() | dbid()]
  defp result(res) do
    IO.puts(res |> inspect())

    case res do
      {:ok, [%Arangox.Response{body: %{"result" => result}}]} -> {:ok, result}
    end
  end

  # we *expect* there to be at least one result, return the core data not
  #   encapsulated in a list. if it doesn't exist, return :dne
  @spec result_one(dbres()) :: {:ok, any()} | {:error, any()}
  defp result_one(res) do
    case result(res) do
      {:ok, [doc]} -> {:ok, doc}
      {:ok, []} -> {:ok, :dne}
      {:error, error} -> {:error, error}
    end
  end

  # similar to result_one, only we guarantee the :ok val will be an ID bitstring
  @spec result_id(dbres()) :: {:ok, bitstring()} | {:error, any()}
  defp result_id(res), do: result_one(res)
end
