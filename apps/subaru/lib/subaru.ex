defmodule Subaru do
  alias Subaru.Query

  # Database Result
  @type dbres() :: Arangox.Response.t()

  @type dbid() :: bitstring()

  @spec upsert(map(), map(), map(), bitstring()) :: dbid()
  def upsert(d_search, d_insert, d_update, collection) do
    Query.new()
    |> Query.upsert(d_search, d_insert, d_update, collection)
    |> Query.exec()
    |> result_id()
  end

  @spec insert(map(), bitstring()) :: dbid()
  def insert(doc, collection) do
    Query.new()
    |> Query.insert(doc, collection)
    |> Query.exec()
    |> result_id()
  end

  @spec insert_edge(bitstring(), bitstring(), bitstring()) :: dbid()
  def insert_edge(from_id, to_id, edge_collection) do
    Query.new()
    |> Query.insert(%{_from: from_id, _to: to_id}, edge_collection)
    |> Query.exec()
    |> result_id()
  end

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

  @spec result(dbres()) :: [map()]
  def result(%Arangox.Response{body: %{"result" => res}}), do: res

  @spec result_one(dbres()) :: map()
  def result_one(res) do
    [r] = result(res)
    r
  end

  @spec result_id(dbres()) :: dbid()
  def result_id(res), do: result_one(res)["_id"]
end
