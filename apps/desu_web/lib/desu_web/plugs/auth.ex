defmodule DesuWeb.Plugs.Auth do
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
  end

  defp get_user_id(conn) do
    conn
    |> Plug.Conn.get_session("user_id")
  end
end
