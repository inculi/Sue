defmodule DesuWeb.OedoController do
  use DesuWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
