defmodule Sue.DB.Migrations.M1697021096 do
  @moduledoc """
  Add fields to Account
  """

  # alias Sue.DB.Schema
  alias Sue.Models.Account
  alias Subaru.Query

  def run() do
    doc = %{"_key" => "x._key", "is_premium" => false, "is_admin" => false}

    Query.new()
    |> Query.for(:x, Account.collection())
    |> Query.filter({:==, "x.is_premium", nil})
    |> Query.update_with("x", doc, Account.collection())
    |> Query.exec()

    :ok
  end

  def vsn() do
    {0, 2, 1}
  end
end
