defmodule Subaru do
  require Logger
  alias Subaru.Query

  # Database Result
  # Arangox.Response.t()
  @type dbid() :: bitstring()
  @type res_id() :: {:ok, dbid()} | {:error, any()}

  defguard is_dbid(id) when is_bitstring(id)

  def get(collection, id) do
    Query.new()
    |> Query.get(collection, id)
    |> Query.exec()
    |> result_one()
  end

  def get!(collection, id) do
    {:ok, res} = get(collection, id)
    res
  end

  @doc """
  Upserts and returns the ID to the document.
  """
  @spec upsert(map(), map(), map(), bitstring()) :: res_id()
  def upsert(d_search, d_insert, d_update, collection) do
    Query.new()
    |> Query.upsert(d_search, d_insert, d_update, collection)
    |> Query.return("NEW._id")
    |> Query.exec()
    |> result_id()
  end

  @doc """
  Upserts and returns the new document.
  """
  @spec upsert_return(map(), map(), map(), bitstring()) :: any()
  def upsert_return(d_search, d_insert, d_update, collection) do
    Query.new()
    |> Query.upsert(d_search, d_insert, d_update, collection)
    |> Query.return("NEW")
    |> Query.exec()
    |> result_one()
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

  @spec upsert_edge(dbid(), dbid(), bitstring()) :: res_id()
  def upsert_edge(from_id, to_id, edge_collection) do
    doc = %{_from: from_id, _to: to_id}

    Query.new()
    |> Query.upsert(doc, doc, %{}, edge_collection)
    |> Query.exec()
    |> result_id()
  end

  @spec remove_all(bitstring()) :: Subaru.DB.res()
  def remove_all(collection) do
    Query.new()
    |> Query.for(:x, collection)
    |> Query.remove(:x, collection)
    |> Query.exec()
    |> result()
  end

  def all(collection) do
    Query.new()
    |> Query.for(:x, collection)
    |> Query.return("x")
    |> Query.exec()
    |> result()
  end

  def all!(collection) do
    {:ok, res} = all(collection)
    res
  end

  @doc """
  Finds and returns document according to filter.
  """
  @spec find_one(bitstring(), Query.boolean_expression()) :: {:ok, any()} | {:error, :dne}
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

  def exists?(collection, expr) do
    case find_one!(collection, expr) do
      :dne -> false
      _ -> true
    end
  end

  def exists_edge?(edge_collection, from_id, to_id) do
    expr = {:and, {:==, "x._from", from_id}, {:==, "x._to", to_id}}
    exists?(edge_collection, expr)
  end

  # GRAPH TRAVERSAL

  # ===============
  @spec traverse_v(
          [bitstring(), ...],
          Query.edge_direction(),
          dbid(),
          integer() | nil,
          integer() | nil,
          map(),
          Query.boolean_expression()
        ) :: {:ok, [map()]} | {:error, any()}
  def traverse_v(
        [edge_collection | _] = ecolls,
        direction,
        startvert,
        min \\ nil,
        max \\ nil,
        options \\ %{},
        filter \\ nil
      )
      when is_bitstring(edge_collection) do
    Query.new()
    |> Query.traverse_for_v(ecolls, direction, startvert, min, max)
    |> Query.options(options)
    |> Query.filter(filter)
    |> Query.return("v")
    |> Query.exec()
    |> result()
  end

  # RESULT OUTPUT HELPERS
  # =====================

  defp result({:ok, [%Arangox.Response{body: %{"result" => result}}]}) do
    # Logger.debug(result |> inspect())
    {:ok, result}
  end

  defp result({:error, e}) do
    # Logger.debug(e |> inspect())
    {:error, e}
  end

  # we *expect* there to be at least one result, return the core data not
  #   encapsulated in a list. if it doesn't exist, return :dne
  @spec result_one(Subaru.DB.res()) :: {:ok, any()} | {:error, any()}
  defp result_one(res) do
    case result(res) do
      {:ok, [doc]} -> {:ok, doc}
      {:ok, []} -> {:ok, :dne}
      {:error, error} -> {:error, error}
    end
  end

  # similar to result_one, only we guarantee the :ok val will be an ID bitstring
  @spec result_id(Subaru.DB.res()) :: res_id()
  defp result_id(res), do: result_one(res)
end
