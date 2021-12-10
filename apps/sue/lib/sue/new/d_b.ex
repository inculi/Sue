defmodule Sue.New.DB do
  alias Sue.New.{Defn, Account, Chat}

  alias Subaru.WIP.Query

  @spec add_defn(Defn.t(), Account.t(), Chat.t()) :: any
  def add_defn(defn, account, chat) do
    defn_doc = Subaru.Vertex.doc(defn)
    defn_coll = Subaru.Vertex.collection(defn)

    acc_doc = Subaru.Vertex.doc(account)
    acc_coll = Subaru.Vertex.collection(account)

    chat_doc = Subaru.Vertex.doc(chat)
    chat_coll = Subaru.Vertex.collection(chat)

    q_defn =
      Query.new()
      |> Query.upsert(defn_doc, defn_doc, %{}, defn_coll)

    q_acc =
      Query.new()
      |> Query.upsert(acc_doc, acc_doc, %{}, acc_coll)

    q_chat =
      Query.new()
      |> Query.upsert(chat_doc, chat_doc, %{}, chat_coll)

    Query.new()
    |> Query.let(:accid, q_acc)
    |> Query.let(:chatid, q_chat)
    |> Query.let(:defnid, q_defn)
    |> Query.run()
  end

  def find_one(collection, expr) do
    Query.new()
    |> Query.for(:x, collection)
    |> Query.filter(expr)
    |> Query.limit(1)
    |> Query.return("x")
    |> Query.exec()
    |> result_one()
  end

  def mock() do
    d = Defn.new("megumin", "acute", :text)
    a = Account.resolve(%Account{name: "Robert Dominguez", handle: "tomboysweat"})
  end

  def result(%Arangox.Response{body: %{"result" => res}}), do: res

  def result_one(res) do
    [r] = result(res)
    r
  end
end
