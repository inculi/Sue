defmodule Sue do
  use GenServer
  require Logger

  alias Sue.Commands.{Core, Defns}
  alias Sue.Models.{Message, Response, Attachment, Account}

  @cmd_rate_limit Application.compile_env(:sue, :cmd_rate_limit)

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

    Logger.info("[Sue] Processed msg in #{uSecs / 1_000_000}s")
    {:noreply, state}
  end

  def handle_cast({:process, msg}, state) do
    spawn(__MODULE__, :execute_in_background, [state.commands, msg])
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

  def send_response(%Message{platform: :discord} = msg, %Response{} = rsp) do
    Logger.info("[Sue] Created response: #{rsp}")
    Sue.Mailbox.Discord.send_response(msg, rsp)
  end

  def send_response(msg, %Attachment{} = att) do
    send_response(msg, %Response{attachments: [att]})
  end

  def send_response(msg, [%Attachment{} | _] = atts) do
    send_response(msg, %Response{attachments: atts})
  end

  @spec process_messages([Message.t()]) :: :ok
  def process_messages(msgs) do
    Enum.each(msgs, fn msg ->
      process_message(msg)
    end)
  end

  @spec debug_blocking_process_message(Message.t()) :: Response.t()
  def debug_blocking_process_message(msg), do: execute_command(get_commands(), msg)

  @spec process_message(Message.t()) :: :ok
  def process_message(%Message{is_ignorable: true}), do: :ok

  def process_message(msg) do
    Logger.info("[Sue] Processing: #{inspect(msg)}")
    GenServer.cast(__MODULE__, {:process, msg})
  end

  def get_commands() do
    GenServer.call(__MODULE__, :get_commands)
  end

  # Iterate through the documentation of our modules' functions. Called once by
  #   this GenServer, and again by Telegram's command setup.
  defp init_commands() do
    for module <- Sue.Utils.list_modules_of_prefix("Elixir.Sue.Commands") do
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
          Logger.error("Couldn't initialize module #{module}: #{e |> inspect()}")
          []
      end
    end
    |> List.flatten()
    |> Enum.reduce(%{}, fn {module, fname, doc}, acc ->
      Map.put(acc, fname, {module, fname, doc})
    end)
  end

  def execute_in_background(commands, msg) do
    {uSecs, :ok} =
      :timer.tc(fn ->
        rsp = execute_command(commands, msg)
        send_response(msg, rsp)
      end)

    Logger.info("[Sue] Processed msg in #{uSecs / 1_000_000}s")

    :ok
  end

  @spec execute_command(map(), Message.t()) :: Response.t()
  defp execute_command(_, %Message{account: %Account{is_banned: true, ban_reason: ban_reason}}) do
    %Response{
      body: "User is banned for reason: '#{ban_reason}'. May God have mercy on your soul."
    }
  end

  defp execute_command(commands, %Message{account: %Account{id: account_id}} = msg) do
    # Check rate limit for sending commands - 5 cmds per 5 seconds
    with :ok <- Sue.Limits.check_rate("sue-command:#{account_id}", @cmd_rate_limit) do
      {module, f, _} =
        case Map.get(commands, msg.command) do
          nil -> {Defns, :calldefn, ""}
          {module, fname, doc} -> {module, String.to_atom("c_" <> fname), doc}
        end

      apply(module, f, [msg])
    else
      :deny -> %Response{body: "Please slow down your requests."}
    end
  end

  # Functions starting with c_ are actually callable Sue commands, and are thus
  #   the only ones we care to initialize.
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
