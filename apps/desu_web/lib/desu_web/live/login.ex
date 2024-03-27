defmodule DesuWeb.Live.Login do
  use Phoenix.LiveView
  use DesuWeb, :verified_routes

  def render(%{page: "loading"} = assigns) do
    ~L""
  end

  def render(assigns) do
    ~L"""
    <div class="flex justify-center items-center h-screen bg-gray-100">
    <div class="w-full max-w-xs">
    <h2 class="text-center text-2xl font-bold mb-3">Login</h2>
    <p class="text-center mb-6">Send <b>!login</b> to Sue to get a code.</p>
    <form class="bg-white shadow-md rounded px-8 pt-6 pb-8 mb-4" phx-submit="verify">
      <div class="mb-4">
        <input type="text"
               name="logincode"
               value="<%= @logincode %>"
               class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
               placeholder="Enter your code" />
      </div>
      <div class="text-right">
        <button type="submit"
                class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline">
          Login
        </button>
      </div>
    </form>
    </div>
    </div>
    """
  end

  def mount(params, session, socket) do
    case connected?(socket) do
      true -> connected_mount(params, session, socket)
      false -> {:ok, assign(socket, page: "loading")}
    end
  end

  defp connected_mount(_params, _session, socket) do
    {:ok, assign(socket, :logincode, "")}
  end

  def handle_event("verify", %{"logincode" => logincode}, socket) do
    with {:ok, true} <- Desu.Login.try_and_expire_code(logincode) do
      {:noreply, socket}
    else
      {:ok, false} ->
        {:noreply, socket |> put_flash(:error, "Code invalid.") |> redirect(to: ~p"/login")}
    end
  end
end
