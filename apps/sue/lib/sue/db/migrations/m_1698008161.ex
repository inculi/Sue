defmodule Sue.DB.Migrations.M1698008161 do
  @moduledoc """
  Add fields to Chat.
  """

  alias Sue.Models.Chat
  alias Subaru.Query

  def run() do
    doc = %{"is_ignored" => false}

    Query.new()
    |> Query.for(:x, Chat.collection())
    |> Query.filter({:==, "x.is_ignored", nil})
    |> Query.update_with("x", doc, Chat.collection())
    |> Query.exec()

    :ok
  end

  def vsn() do
    {0, 2, 3}
  end
end
