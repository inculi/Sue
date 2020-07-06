defmodule Sue.Models.Message do
  alias __MODULE__
  alias Sue.Models.{Platform, Account, PlatformAccount, Chat}

  @enforce_keys [:platform, :id, :platform_account, :chat, :body, :is_ignorable]
  defstruct [
    #
    :platform,
    :id,
    #
    :platform_account,
    :chat,
    :account,
    #
    :body,
    :command,
    :args,
    :attachments,
    :time,
    #
    :is_from_sue,
    :is_ignorable,
    :has_attachments
  ]

  @type t() :: %__MODULE__{
          platform: Platform.t(),
          id: integer() | String.t(),
          #
          platform_account: PlatformAccount.t(),
          chat: Chat.t(),
          account: Account.t() | nil,
          #
          body: String.t(),
          command: String.t() | nil,
          args: String.t() | nil,
          attachments: [Attachment.t()] | nil,
          time: DateTime.t() | nil,
          #
          is_from_sue: boolean() | nil,
          is_ignorable: boolean() | nil,
          has_attachments: boolean() | nil
        }

  @spec new(Platform.t(), Keyword.t() | Map.t()) :: Message.t()
  def new(:imessage, kw) do
    [
      id: handle_id,
      person_centric_id: _handle_person_centric_id,
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
      #
      platform_account: %PlatformAccount{platform: :imessage, id: handle_id},
      chat: %Chat{
        platform: :imessage,
        id: chat_id || "direct;#{handle_id}",
        is_direct: chat_id == nil
      },
      #
      body: body,
      time: DateTime.from_unix!(utc_date),
      #
      is_from_sue: from_me,
      is_ignorable: is_ignorable?(:imessage, from_me, body),
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
      platform_account: %PlatformAccount{platform: :telegram, id: msg.from.id},
      body: context.update.message.text |> String.trim(),
      time: DateTime.from_unix!(msg.date),
      chat: %Chat{
        platform: :telegram,
        id: msg.chat.id,
        is_direct: msg.chat.type == "private"
      },
      # account:
      is_from_sue: false,
      is_ignorable: false,
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
      platform_account: %PlatformAccount{platform: :telegram, id: msg.from.id},
      body: body,
      time: DateTime.from_unix!(msg.date),
      chat: %Chat{
        platform: :telegram,
        id: msg.chat.id,
        is_direct: msg.chat.type == "private"
      },
      is_from_sue: false,
      is_ignorable: is_ignorable?(:telegram, false, body),
      has_attachments:
        msg[:photo] != nil or msg[:document] != nil or
          Map.get(msg, :reply_to_message, %{})[:photo] != nil or
          Map.get(msg, :reply_to_message, %{})[:document] != nil
    }
    |> augment_one()
  end

  # TODO: Finish implementing this.
  def new(:debug, text) do
    %Message{
      platform: :debug,
      id: 0,
      platform_account: %PlatformAccount{platform: :debug, id: 0},
      body: text,
      time: DateTime.utc_now(),
      chat: %Chat{platform: :debug, id: 0, is_direct: true},
      is_from_sue: false,
      is_ignorable: is_ignorable?(:debug, false, text),
      has_attachments: false
    }
  end

  # First stage of adding new fields to our Message. Primarily concerned with
  #   parsing commands, args, stripping whitespace.
  @spec augment_one(Message.t()) :: Message.t()

  defp augment_one(%Message{is_ignorable: true} = msg), do: msg

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
  @spec augment_two(Message.t()) :: Message.t()
  def augment_two(%Message{} = msg) do
    account = Account.resolve(msg.platform_account)
    %Message{msg | account: account}
  end

  @spec parse_command(Message.t(), String.t()) :: Message.t()
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

  defp is_ignorable?(:telegram, _from_me, body) do
    not Regex.match?(~r/^\/(?! )./u, body |> String.trim_leading())
  end

  defp is_ignorable?(platform, _from_me, body) when platform in [:imessage, :debug] do
    not Regex.match?(~r/^!(?! )./u, body |> String.trim_leading())
  end

  # to_string override
  defimpl String.Chars, for: Message do
    def to_string(%Message{
          platform: protocol,
          platform_account: %PlatformAccount{id: bid},
          chat: %Chat{id: cid}
        }) do
      "#Message<#{protocol},#{bid},#{cid}>"
    end
  end
end
