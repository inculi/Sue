defmodule Sue.New.DB do
  alias Sue.New.{Defn, Account, Chat}

  alias Subaru.Query

  @spec add_defn(Defn.t(), Account.t(), Chat.t()) :: any
  def add_defn(defn, account, chat) do
    defn_doc = Subaru.Vertex.doc(defn)
    defn_coll = Subaru.Vertex.collection(defn)

    # q_defn =
    #   Query.new()
    #   |> Query.upsert(defn_doc, defn_doc, %{}, defn_coll)

    # Query.new()
    # |> Query.upsert(%{})

    # Query.new()
    # # |> Query.let(:accid, q_acc)
    # # |> Query.let(:chatid, q_chat)
    # |> Query.let(:defnid, q_defn)
    # |> Query.run()
  end

  def mock() do
    d = Defn.new("megumin", "acute", :text)

    a =
      Account.resolve(%Account{
        name: "Robert Dominguez",
        handle: "tomboysweat",
        platform_id: {"telegram", 123}
      })
  end
end
