defmodule Sue.DB.Account do
  alias Sue.DB

  def db_tables() do
    [
      {
        :accounts,
        [
          type: :set,
          attributes: [:key, :val]
        ]
      }
    ]
  end

  @spec obtain_id(Atom.t(), any()) :: reference()
  def obtain_id(platform, platform_specific_id) do
    key = {platform, platform_specific_id}

    with nil <- DB.get!(:accounts, key) do
      id = make_ref()
      DB.set({:accounts, key, id})
      id
    else
      id -> id
    end
  end
end
