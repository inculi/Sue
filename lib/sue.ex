defmodule Sue do
  use GenServer
  require Logger

  alias Sue.Commands.{Core, Defns, Images, Rand, Shell}
  alias Sue.Models.{Message, Response, Attachment}

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
  def handle_cast({:process, %Message{command: "help"} = msg}, state) do
    {uSecs, :ok} =
      :timer.tc(fn ->
        rsp = Core.help(msg, state.commands)
        send_response(msg, rsp)
      end)

    Logger.debug("[Sue] Processed msg #{inspect(msg.sue_id)} in #{uSecs / 1_000_000}s")
    {:noreply, state}
  end

  def handle_cast({:process, msg}, state) do
    {uSecs, :ok} =
      :timer.tc(fn ->
        {module, f} =
          case Map.get(state.commands, msg.command) do
            nil -> {Defns, :calldefn}
            {module, fname} -> {module, String.to_atom("c_" <> fname)}
          end

        rsp = apply(module, f, [msg])
        send_response(msg, rsp)
      end)

    Logger.debug("[Sue] Processed msg #{inspect(msg.sue_id)} in #{uSecs / 1_000_000}s")
    {:noreply, state}
  end

  def send_response(%Message{platform: :imessage} = msg, %Response{} = rsp) do
    Logger.debug("[Sue] Created response: #{rsp}")
    Sue.Mailbox.IMessage.send_response(msg, rsp)
  end

  def send_response(msg, %Attachment{} = att) do
    send_response(msg, %Response{attachments: [att]})
  end

  def send_response(msg, [%Attachment{} | _] = atts) do
    send_response(msg, %Response{attachments: atts})
  end

  @spec process_messages([Message.t()]) :: :ok
  def process_messages(msgs) do
    for msg <- msgs do
      if !msg.ignorable do
        Task.start(fn -> process_message(msg) end)
      end
    end

    :ok
  end

  defp process_message(msg) do
    Logger.debug("[Sue] Processing: #{inspect(msg)}")
    GenServer.cast(__MODULE__, {:process, msg |> Message.augment_two()})
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
