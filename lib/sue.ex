defmodule Sue do
  use GenServer
  require Logger

  alias Sue.Commands.{Core, Defns, Images, Rand, Shell, Poll}
  alias Sue.Models.{Message, Response, Attachment}

  @modules [Core, Defns, Images, Rand, Shell, Poll]

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
  def handle_call(:get_commands, _from, state) do
    {:reply, state.commands, state}
  end

  @impl true
  def handle_cast({:process, %Message{command: "help"} = msg}, state) do
    {uSecs, :ok} =
      :timer.tc(fn ->
        rsp = Core.help(msg, state.commands)
        send_response(msg, rsp)
      end)

    Logger.info("[Sue] Processed msg #{inspect(msg.sue_id)} in #{uSecs / 1_000_000}s")
    {:noreply, state}
  end

  def handle_cast({:process, msg}, state) do
    {uSecs, :ok} =
      :timer.tc(fn ->
        {module, f, _} =
          case Map.get(state.commands, msg.command) do
            nil -> {Defns, :calldefn, ""}
            {module, fname, doc} -> {module, String.to_atom("c_" <> fname), doc}
          end

        rsp = apply(module, f, [msg])
        send_response(msg, rsp)
      end)

    Logger.info("[Sue] Processed msg #{inspect(msg.sue_id)} in #{uSecs / 1_000_000}s")
    {:noreply, state}
  end

  @spec send_response(Message.t(), Response.t() | Attachment.t() | [Attachment.t()]) :: any()
  def send_response(%Message{platform: :imessage} = msg, %Response{} = rsp) do
    Logger.info("[Sue] Created response: #{rsp}")
    Sue.Mailbox.IMessage.send_response(msg, rsp)
  end

  def send_response(%Message{platform: :telegram} = msg, %Response{} = rsp) do
    Logger.info("[Sue] Created response: #{rsp}")
    Sue.Mailbox.Telegram.send_response(msg, rsp)
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
    msg = msg |> Message.augment_two()
    Logger.info("[Sue] Processing: #{inspect(msg)}")
    GenServer.cast(__MODULE__, {:process, msg})
  end

  def get_commands() do
    GenServer.call(__MODULE__, :get_commands)
  end

  # Iterate through the documentation of our modules' functions. Called once by
  #   this GenServer, and again by Telegram's command setup.
  defp init_commands() do
    for module <- @modules do
      with {_, _, _, _, _, _, func_docs} <- Code.fetch_docs(module) do
        func_docs
        |> Enum.map(fn func_doc_tuple ->
          case func_doc_tuple do
            {{:function, fname_a, _arity}, _num_lines, _, doc, _} ->
              make_func_doc_tuple(module, Atom.to_string(fname_a), doc)

            _ ->
              []
          end
        end)
      else
        e ->
          IO.inspect(e)
          []
      end
    end
    |> List.flatten()
    |> Enum.reduce(%{}, fn {module, fname, doc}, acc ->
      Map.put(acc, fname, {module, fname, doc})
    end)
  end

  defp make_func_doc_tuple(module, "c_" <> fname, %{"en" => doc}) do
    {module, fname, doc}
  end

  defp make_func_doc_tuple(module, "c_" <> fname, :none) do
    {module, fname, ""}
  end

  defp make_func_doc_tuple(_, _, _), do: []

  def post_init() do
    # Set Telegram method descriptions.
    for {_module, fname, doc} <- get_commands() |> Map.values() do
      desc = doc |> String.split("\n", parts: 2) |> hd()

      desc =
        if String.length(desc) >= 3 do
          desc
        else
          "No description yet."
        end

      %ExGram.Model.BotCommand{
        command: fname,
        description: desc
      }
    end
    |> ExGram.set_my_commands()
  end
end
