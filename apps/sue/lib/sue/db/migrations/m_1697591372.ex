defmodule Sue.DB.Migrations.M1697591372 do
  @moduledoc """
  Add fields to Account.
  """

  alias Sue.Models.Account
  alias Subaru.Query

  def run() do
    doc = %{"is_banned" => false, "ban_reason" => "", "is_ignored" => false}

    Query.new()
    |> Query.for(:x, Account.collection())
    |> Query.filter({:==, "x.is_banned", nil})
    |> Query.update_with("x", doc, Account.collection())
    |> Query.exec()

    :ok
  end

  def vsn() do
    {0, 2, 2}
  end
end
