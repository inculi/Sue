defmodule Sue.Models.Message do
  alias __MODULE__
  alias Sue.Models.{Account, Buddy, Chat}

  @type t() :: %__MODULE__{}
  defstruct [
    :platform,
    :id,
    :sue_id,
    :buddy,
    :body,
    :time,
    :chat,
    :account,
    :from_me,
    :ignorable,
    :attachments,
    :has_attachments,
    :command,
    :args
  ]

  @spec new(:imessage | :telegram, Keyword.t() | Map.t()) :: Message.t()
  def new(:imessage, kw) do
    [
      id: handle_id,
      person_centric_id: handle_person_centric_id,
      cache_has_attachments: has_attachments,
      text: body,
      ROWID: message_id,
      cache_roomnames: chat_id,
      is_from_me: from_me,
      utc_date: utc_date
    ] = kw

    from_me = from_me == 1

    %Message{
      platform: :imessage,
      id: message_id,
      sue_id: make_ref(),
      buddy: %Buddy{id: handle_id, guid: handle_person_centric_id},
      body: body,
      time: DateTime.from_unix!(utc_date),
      chat: %Chat{
        platform: :imessage,
        id: chat_id || "direct;#{handle_id}",
        is_direct: chat_id == nil
      },
      from_me: from_me,
      ignorable: is_ignorable?(:imessage, from_me, body),
      has_attachments: has_attachments == 1
    }
    |> augment_one()
  end

  def new(:telegram, %{msg: msg, command: command, context: context}) do
    # When multiple bots are in the same chat, telegram sometimes suffixes
    #   commands with bot names
    botnameSuffix = "@" <> context.bot_info.username

    command =
      cond do
        String.ends_with?(command, botnameSuffix) ->
          String.slice(command, 0, String.length(command) - String.length(botnameSuffix))

        true ->
          command
      end

    %Message{
      platform: :telegram,
      id: msg.chat.id,
      sue_id: make_ref(),
      buddy: %Buddy{id: msg.from.id},
      body: context.update.message.text |> String.trim(),
      time: DateTime.from_unix!(msg.date),
      chat: %Chat{
        platform: :telegram,
        id: msg.chat.id,
        is_direct: msg.chat.type == "private"
      },
      # account:
      from_me: false,
      ignorable: false,
      # attachments:
      has_attachments:
        Map.get(msg, :reply_to_message, %{})[:photo] != nil or
          Map.get(msg, :reply_to_message, %{})[:document] != nil,
      command: command,
      args: msg.text
    }
  end

  def new(:telegram, %{msg: msg, context: _context}) do
    # No command specified, so we have to parse it from the body.
    body = Map.get(msg, :caption, "")

    %Message{
      platform: :telegram,
      id: msg.chat.id,
      sue_id: make_ref(),
      buddy: %Buddy{id: msg.from.id},
      body: body,
      time: DateTime.from_unix!(msg.date),
      chat: %Chat{
        platform: :telegram,
        id: msg.chat.id,
        is_direct: msg.chat.type == "private"
      },
      from_me: false,
      ignorable: is_ignorable?(:telegram, false, body),
      has_attachments:
        msg[:photo] != nil or msg[:document] != nil or
          Map.get(msg, :reply_to_message, %{})[:photo] != nil or
          Map.get(msg, :reply_to_message, %{})[:document] != nil
    }
    |> augment_one()
  end

  # First stage of adding new fields to our Message. Primarily concerned with
  #   parsing commands, args, stripping whitespace.
  defp augment_one(%Message{ignorable: true} = msg), do: msg

  defp augment_one(%Message{platform: :imessage} = msg) do
    "!" <> newbody = msg.body |> String.trim()
    parse_command(msg, newbody)
  end

  defp augment_one(%Message{platform: :telegram} = msg) do
    "/" <> newbody = msg.body |> String.trim()
    parse_command(msg, newbody)
  end

  # Second stage of adding new fields to our Message. Primarily concerned with
  #   resolving fields that map to elements in our database (Accounts, etc.)
  def augment_two(%Message{} = msg) do
    account = Account.resolve_and_relate(msg)
    %Message{msg | account: account}
  end

  defp parse_command(msg, newbody) do
    [command | args] = String.split(newbody, " ", parts: 2)

    %Message{
      msg
      | body: newbody,
        command: command |> String.downcase(),
        args: if(args == [], do: "", else: args |> hd())
    }
  end

  # This binary classifier will grow in complexity over time.
  defp is_ignorable?(_platform, true, _body), do: true

  defp is_ignorable?(_platform, _from_me, nil), do: true

  defp is_ignorable?(:imessage, _from_me, body) do
    not Regex.match?(~r/^!(?! )./u, body |> String.trim_leading())
  end

  defp is_ignorable?(:telegram, _from_me, body) do
    not Regex.match?(~r/^\/(?! )./u, body |> String.trim_leading())
  end

  # to_string override
  defimpl String.Chars, for: Message do
    def to_string(%Message{
          platform: protocol,
          buddy: %Buddy{id: bid},
          chat: %Chat{id: cid},
          sue_id: sid
        }) do
      "#Message<#{protocol},#{bid},#{cid},#{sid |> inspect()}>"
    end
  end
end
