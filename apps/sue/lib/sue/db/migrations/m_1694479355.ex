defmodule Sue.DB.Migrations.M1694479355 do
  @moduledoc """
  https://github.com/inculi/Sue/pull/45

  Move Account.platform_id metadata into a PlatformAccount.
  Create connect the two via an edge (sue_user_by_platformaccount).
  """

  def run() do
    :ok
  end

  def vsn() do
    {0, 1, 1}
  end
end
