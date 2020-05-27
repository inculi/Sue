defmodule Sue do
  use GenServer
  require Logger

  alias Sue.Commands.{Core, Defns, Images, Rand, Shell}

  @modules [Core, Defns, Images, Rand, Shell]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    state = %{
      commands: init_commands()
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:process, %Sue.Models.Message{command: "help"} = msg}, state) do
    rsp = Core.help(msg, state.commands)
    send_response(msg, rsp)
    {:noreply, state}
  end

  def handle_cast({:process, msg}, state) do
    {module, f} =
      case Map.get(state.commands, msg.command) do
        nil -> {Defns, :calldefn}
        {module, fname} -> {module, String.to_atom("c_" <> fname)}
      end

    rsp = apply(module, f, [msg])
    Logger.debug("Created response: #{rsp}")
    send_response(msg, rsp)

    {:noreply, state}
  end

  def send_response(%Sue.Models.Message{platform: :imessage} = msg, rsp) do
    Sue.Mailbox.IMessage.send_response(msg, rsp)
  end

  @spec process_messages([Sue.Models.Message.t()]) :: :ok
  def process_messages(msgs) do
    for msg <- msgs do
      if !msg.ignorable do
        Task.start(fn -> process_message(msg) end)
      end
    end

    :ok
  end

  defp process_message(msg) do
    Logger.debug("Processing: #{inspect(msg)}")
    GenServer.cast(__MODULE__, {:process, msg |> Sue.Models.Message.augment_two()})
  end

  defp init_commands() do
    @modules
    |> Enum.flat_map(fn module ->
      module.__info__(:functions)
      |> Keyword.keys()
      |> Enum.map(&Atom.to_string/1)
      |> Enum.filter(fn f -> String.starts_with?(f, "c_") end)
      |> Enum.map(fn "c_" <> fname -> {module, fname} end)
    end)
    |> Enum.reduce(%{}, fn {module, fname}, acc -> Map.put(acc, fname, {module, fname}) end)
  end
end
