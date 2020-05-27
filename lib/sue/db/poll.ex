defmodule Sue.DB.Poll do
  alias Sue.DB

  def db_tables() do
    [
      {
        :polls,
        [
          type: :set,
          attributes: [:platform, :chatid, :poll],
          index: [:chatid]
        ]
      }
    ]
  end

  def set(platform, chatid, poll) when is_atom(platform) and is_map(poll) do
    DB.set({:polls, {platform, chatid}, poll})
  end

  def get(platform, chatid) do
    DB.get(:polls, {platform, chatid})
  end
end
