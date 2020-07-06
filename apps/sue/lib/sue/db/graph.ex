defmodule Sue.DB.Graph do
  alias :mnesia, as: Mnesia
  alias Sue.DB
  alias Sue.DB.Schema.Vertex

  @type result() :: {:ok, any()} | {:error, any()}
  @edge_table :edges

  # Public API
  @doc """
  Check if a Vertex exists in our graph.
  """
  @spec exists?(Vertex.t()) :: boolean()
  def exists?(v) do
    {:ok, res} = t_exists?(v) |> DB.exec()
    res
  end

  @spec t_exists?(Vertex.t()) :: fun()
  defp t_exists?(v) do
    fn ->
      DB.t_read({Vertex.label(v), Vertex.id(v)}).() != []
    end
  end

  @doc """
  Check if a uni-directional edge exists between two vertices.
  """
  @spec exists_uni_edge?(
          Vertex.t() | Vertex.tuple_t(),
          Vertex.t() | Vertex.tuple_t()
        ) :: boolean()
  def exists_uni_edge?(v1, v2) when is_tuple(v1) and is_tuple(v2) do
    {:ok, res} = t_exists_uni_edge?(v1, v2) |> DB.exec()
    res
  end

  def exists_uni_edge?(v1, v2) do
    exists_uni_edge?(
      {Vertex.label(v1), Vertex.id(v1)},
      {Vertex.label(v2), Vertex.id(v2)}
    )
  end

  @spec t_exists_uni_edge?(Vertex.tuple_t(), Vertex.tuple_t()) :: fun()
  defp t_exists_uni_edge?({src_type, src_id}, {dst_type, dst_id}) do
    fn -> t_match_vertex(src_type, dst_type, src_id, dst_id, :_).() != [] end
  end

  @doc """
  Check if a bi-directional edge exists between two vertices.
  """
  @spec exists_bi_edge?(
          Vertex.t() | Vertex.tuple_t(),
          Vertex.t() | Vertex.tuple_t()
        ) :: boolean()
  def exists_bi_edge?(v1, v2) when is_tuple(v1) and is_tuple(v2) do
    {:ok, res} = t_exists_bi_edge?(v1, v2) |> DB.exec()
    res
  end

  def exists_bi_edge?(v1, v2) do
    exists_bi_edge?(
      {Vertex.label(v1), Vertex.id(v1)},
      {Vertex.label(v2), Vertex.id(v2)}
    )
  end

  @spec t_exists_bi_edge?(Vertex.tuple_t(), Vertex.tuple_t()) :: fun()
  defp t_exists_bi_edge?({src_type, src_id}, {dst_type, dst_id}) do
    fn ->
      t_exists_uni_edge?({src_type, src_id}, {dst_type, dst_id}).() and
        t_exists_uni_edge?({dst_type, dst_id}, {src_type, src_id}).()
    end
  end

  @doc """
  Add a uni-directional edge to the graph.
  """
  @spec add_uni_edge(Vertex.t(), Vertex.t(), Map.t()) :: result()
  def add_uni_edge(v1, v2, metadata \\ %{}) do
    t_add_uni_edge(v1, v2, metadata) |> DB.exec()
  end

  @spec t_add_uni_edge(Vertex.t(), Vertex.t(), Map.t()) :: fun()
  defp t_add_uni_edge(v1, v2, metadata) do
    DB.t_write({
      @edge_table,
      Vertex.label(v1),
      Vertex.label(v2),
      Vertex.id(v1),
      Vertex.id(v2),
      metadata
    })
  end

  @doc """
  Add a bi-directional edge to the graph.
  """
  @spec add_bi_edge(Vertex.t(), Vertex.t(), Map.t()) :: result()
  def add_bi_edge(v1, v2, metadata \\ %{}) do
    t_add_bi_edge(v1, v2, metadata) |> DB.exec()
  end

  @spec t_add_bi_edge(Vertex.t(), Vertex.t(), Map.t()) :: fun()
  defp t_add_bi_edge(v1, v2, metadata \\ %{}) do
    fn ->
      t_add_uni_edge(v1, v2, metadata).()
      t_add_uni_edge(v2, v1, metadata).()
    end
  end

  @doc """
  Create a vertex.
  """
  @spec add_vertex(Vertex.t()) :: result()
  def add_vertex(v) do
    t_add_vertex(v) |> DB.exec()
  end

  @spec t_add_vertex(Vertex.t()) :: fun()
  def t_add_vertex(v) do
    DB.t_write({Vertex.label(v), Vertex.id(v), v})
  end

  @spec upsert_vertex(Vertex.t()) :: result()
  def upsert_vertex(v) do
    t_upsert_vertex(v) |> DB.exec()
  end

  @spec t_upsert_vertex(Vertex.t()) :: fun()
  defp t_upsert_vertex(v) do
    table = Vertex.label(v)
    id = Vertex.id(v)

    fn ->
      case Mnesia.read({table, id}) do
        [] -> Mnesia.write({table, id, v})
        [_record] -> :exists
      end
    end
  end

  @spec upsert_bi_edge(Vertex.t(), Vertex.t()) :: result()
  def upsert_bi_edge(v1, v2) do
    t_upsert_bi_edge(v1, v2) |> DB.exec()
  end

  @spec t_upsert_bi_edge(Vertex.t(), Vertex.t()) :: fun()
  defp t_upsert_bi_edge(v1, v2) do
    fn ->
      t_upsert_vertex(v1).()
      t_upsert_vertex(v2).()
      t_add_bi_edge(v1, v2, %{}).()
    end
  end

  # TODO: Horrid naming, tbh. Redo in a more generic way that lets us specify
  #   the max number of edges we are allowed to associate with a vertex.
  #   Preferably we'd specify that number in the schema. (In this case, max=1
  #   (thus the `if_unique`))
  @spec getsert_bi_edge_if_unique(Vertex.t(), Vertex.t()) :: result()
  def getsert_bi_edge_if_unique(v1, v2) do
    t_getsert_bi_edge_if_unique(v1, v2) |> DB.exec()
  end

  @spec t_getsert_bi_edge_if_unique(Vertex.t(), Vertex.t()) :: fun()
  defp t_getsert_bi_edge_if_unique(v1, v2) do
    fn ->
      case t_upsert_vertex(v1).() do
        # v1 already exists. Check if it links with another vert of v2's type.
        :exists ->
          case t_adjacent(v1, Vertex.label(v2)).() do
            [] ->
              t_add_vertex(v2).()
              t_add_bi_edge(v1, v2).()

            [{dst_type, dst_id}] ->
              [{_table, _key, val}] = DB.t_read({dst_type, dst_id}).()
              val
          end

        # v1 doesn't exist, can't have edges.
        :ok ->
          # perform the -sert
          t_upsert_bi_edge(v1, v2).()
          # perform the get-
          v2
      end
    end
  end

  @doc """
  Get 1-hop neighbors of vertex.
  """
  @spec adjacent(Vertex.t() | Vertex.tuple_t(), atom(), :_ | map()) :: result()
  def adjacent(v, dst_type \\ :_, metadata \\ :_)

  def adjacent(v, dst_type, metadata) do
    t_adjacent(v, dst_type, metadata) |> DB.exec()
  end

  @spec t_adjacent(Vertex.t() | Vertex.tuple_t(), atom(), :_ | map()) :: fun()
  defp t_adjacent(src_v, dst_type, metadata \\ :_)

  defp t_adjacent({src_type, src_id}, dst_type, metadata) do
    fn ->
      for {@edge_table, _src_type, dst_type, _src_id, dst_id, _metadata} <-
            t_match_vertex(src_type, dst_type, src_id, :_, metadata).() do
        {dst_type, dst_id}
      end
    end
  end

  defp t_adjacent(v, dst_type, metadata) do
    t_adjacent({Vertex.label(v), Vertex.id(v)}, dst_type, metadata)
  end

  @doc """
  Continually fetch neighbors of specified hop types
  """
  @spec path(Vertex.t() | Vertex.tuple_t(), [Vertex.module_name_t()]) :: result()
  def path(v_start, hop_layers), do: t_path(v_start, hop_layers) |> DB.exec()

  @spec t_path(Vertex.t() | Vertex.tuple_t(), [Vertex.module_name_t()]) :: fun()
  def t_path(v_start, []), do: v_start

  def t_path(v_start, [hop_type | hop_layer_types]) do
    fn ->
      for next_hop <- t_adjacent(v_start, hop_type).() do
        t_path(next_hop, hop_layer_types).()
      end
      |> List.flatten()
      |> Enum.filter(fn v -> not Vertex.equals?(v_start, v) end)
    end
  end

  def match_vertex(src_type, dst_type, src_id, dst_id, metadata) do
    t_match_vertex(src_type, dst_type, src_id, dst_id, metadata)
    |> DB.exec()
  end

  defp t_match_vertex(src_type, dst_type, src_id, dst_id, metadata) do
    DB.t_match({@edge_table, src_type, dst_type, src_id, dst_id, metadata})
  end

  # Internal Methods :: Utility
  @spec elixirize_output({:aborted, any} | {:atomic, any}) :: {:error, any} | {:ok, any}
  def elixirize_output(out) do
    case out do
      {:atomic, res} -> {:ok, res}
      {:aborted, reason} -> {:error, reason}
    end
  end
end
