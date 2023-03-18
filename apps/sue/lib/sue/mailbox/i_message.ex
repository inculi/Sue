defmodule Sue.Mailbox.IMessage do
  use GenServer

  require Logger

  alias Sue.Models.{Message, Response, Attachment}
  alias Sue.New.Chat

  @applescript_dir Path.join(:code.priv_dir(:sue), "applescript/")
  @update_interval 1_000
  @cache_table :suestate_cache

  def start_link(args) do
    Logger.info("Starting IMessage genserver...")
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    # https://blog.appsignal.com/2019/05/14/elixir-alchemy-background-processing.html
    Process.send_after(self(), :get_updates, @update_interval)
    {:ok, nil}
  end

  def handle_info(:get_updates, _last_run_at) do
    get_updates()
    Process.send_after(self(), :get_updates, @update_interval)
    {:noreply, :calendar.local_time()}
  end

  # === INBOX ===
  @spec get_updates :: :ok
  def get_updates() do
    get_current_max_rowid()
    |> query_messages_since()
    |> process_messages()
  end

  def send_response(_msg, %Response{body: nil, attachments: []}), do: :ok

  def send_response(msg, %Response{attachments: []} = rsp) do
    send_response_text(msg, rsp)
  end

  def send_response(msg, %Response{body: nil, attachments: atts}) do
    send_response_attachments(msg, atts)
  end

  def send_response(msg, %Response{attachments: atts} = rsp) do
    send_response_text(msg, rsp)
    send_response_attachments(msg, atts)
  end

  # === OUTBOX ===
  defp send_response_text(%Message{chat: %Chat{is_direct: true}} = msg, rsp) do
    {_platform, account_id} = msg.account.platform_id

    args = [
      Path.join(@applescript_dir, "SendTextSingleBuddy.scpt"),
      rsp.body,
      account_id
    ]

    System.cmd("osascript", args)
    :ok
  end

  defp send_response_text(%Message{chat: %Chat{is_direct: false}} = msg, rsp) do
    {_platform, chat_id} = msg.chat.platform_id

    args = [
      Path.join(@applescript_dir, "SendText.scpt"),
      rsp.body,
      "iMessage;+;" <> chat_id
    ]

    System.cmd("osascript", args)
    :ok
  end

  defp send_response_attachments(_msg, []), do: :ok

  defp send_response_attachments(%Message{chat: %Chat{is_direct: true}} = msg, [att | atts]) do
    {_platform, account_id} = msg.account.platform_id

    args = [
      Path.join(@applescript_dir, "SendImageSingleBuddy.scpt"),
      att.filename,
      account_id
    ]

    System.cmd("osascript", args)
    send_response_attachments(msg, atts)
  end

  defp send_response_attachments(%Message{chat: %Chat{is_direct: false}} = msg, [att | atts]) do
    {_platform, chat_id} = msg.chat.platform_id

    args = [
      Path.join(@applescript_dir, "SendImage.scpt"),
      att.filename,
      "iMessage;+;" <> chat_id
    ]

    System.cmd("osascript", args)
    send_response_attachments(msg, atts)
  end

  # === UTILS ===
  defp process_messages([]), do: :ok

  defp process_messages(msgs) do
    msgs
    |> Enum.sort_by(fn m -> Keyword.get(m, :utc_date) end)
    |> Enum.map(fn m -> Message.from_imessage(m) end)
    |> add_attachments()
    |> set_new_max_rowid()
    |> Sue.process_messages()
  end

  defp add_attachments(msgs) do
    msgs_with_attachments = Enum.filter(msgs, fn m -> m.has_attachments end)

    attachments =
      case msgs_with_attachments do
        [] ->
          []

        _ ->
          (msgs_with_attachments
           |> Enum.min_by(fn m -> m.id end)).id
          |> query_attachments_since()
          |> Enum.map(fn a -> Attachment.new(a, :imessage) end)
          |> Enum.filter(fn a -> a.mime_type != nil end)
          |> Enum.group_by(fn a -> a.message_id end)
      end

    Logger.debug("Attachments: #{attachments |> inspect()}")

    newmsgs =
      msgs
      |> Enum.map(fn m ->
        if m.has_attachments do
          %Message{m | attachments: Map.get(attachments, m.id)}
        else
          %Message{m | attachments: []}
        end
      end)

    Logger.debug("msgs: #{newmsgs |> inspect()}")
    newmsgs
  end

  defp set_new_max_rowid(msgs) do
    rowid = Enum.max_by(msgs, fn m -> m.id end).id
    Subaru.Cache.put(@cache_table, "imsg_max_rowid", rowid)
    # DB.set(:state, "imsg_max_rowid", rowid)
    msgs
  end

  @doc """
  If you delete a bugged chat.db, your message ID counter will reset to 0, but
    Sue will still think that you're at the old, higher ID. This clears the
    cache so that it will just pick up from the next message.

  TODO: A better approach for this is to keep track of the last message ID we
    replied to, and then make some checks on startup to see if this message is
    even still present in the DB.
  """
  def clear_max_rowid() do
    Subaru.Cache.del!(@cache_table, "imsg_max_rowid")
    # DB.del!(:state, "imsg_max_rowid")
  end

  @spec query(String.t()) :: [Keyword.t()]
  defp query(query) do
    {:ok, results} = Sqlitex.Server.query(Sue.IMessageChatDB, query)
    results
  end

  defp get_current_max_rowid() do
    # Check to see if we have one stored.

    case Subaru.Cache.get!(@cache_table, "imsg_max_rowid") do
      nil ->
        # Haven't seen it before, use the max of ROWID.
        [[ROWID: rowid]] = query("SELECT MAX(message.ROWID) AS ROWID FROM message;")
        Subaru.Cache.put(@cache_table, "imsg_max_rowid", rowid)
        rowid

      res ->
        res
    end
  end

  defp query_messages_since(rowid) do
    q = """
    SELECT handle.id, handle.person_centric_id, message.cache_has_attachments, message.text, message.ROWID, message.cache_roomnames, message.is_from_me, message.date/1000000000 + strftime("%s", "2001-01-01") AS utc_date FROM message INNER JOIN handle ON message.handle_id = handle.ROWID WHERE message.ROWID > #{rowid};
    """

    query(q)
  end

  defp query_attachments_since(rowid) do
    Logger.debug("Querying attachments since rowid #{rowid}...?")

    q = """
    SELECT attachment.ROWID AS a_id, message_attachment_join.message_id AS m_id, attachment.filename, attachment.mime_type, attachment.total_bytes FROM attachment INNER JOIN message_attachment_join ON attachment.ROWID == message_attachment_join.attachment_id WHERE message_attachment_join.message_id >= #{rowid};
    """

    query(q)
  end
end
