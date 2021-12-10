defprotocol Subaru.Vertex do
  @spec collection(t) :: String.t()
  def collection(v)

  @spec doc(t) :: Map.t()
  def doc(v)
end
