defmodule Sue.New.DB do
  alias Sue.New.{Defn, Account, Chat}

  @spec add_defn(Defn.t(), Subaru.dbid(), Subaru.dbid()) :: Subaru.dbid()
  def add_defn(defn, account_id, chat_id) do
    defn_id = Subaru.insert(defn)
    Subaru.insert_edge(account_id, defn_id, "sue_defnAuthor")
    Subaru.insert_edge(chat_id, defn_id, "sue_defnChat")

    defn_id
  end

  def mock() do
    d = Defn.new("megumin", "acute", :text)

    a =
      Account.resolve(%Account{
        name: "Robert Dominguez",
        handle: "tomboysweat",
        platform_id: {"telegram", 123}
      })

    c =
      Chat.resolve(%Chat{
        platform_id: {"telegram", 456},
        is_direct: false
      })

    add_defn(d, a.id, c.id)
  end
end
