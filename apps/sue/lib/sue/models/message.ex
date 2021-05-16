defmodule Sue.Models.Message do
  require Logger

  alias __MODULE__
  alias Sue.Models.{Platform, Account, PlatformAccount, Chat, Attachment}

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

    Logger.debug("from_me: #{from_me}")
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

  # def new(:telegram, %{msg: msg, command: command, context: context}) do
  #   # When multiple bots are in the same chat, telegram sometimes suffixes
  #   #   commands with bot names

  #   Logger.info("new 1 called")

  #   command =
  #     parse_command_potentially_with_botname_suffix(command, "@" <> context.bot_info.username)

  #   %Message{
  #     platform: :telegram,
  #     id: msg.chat.id,
  #     platform_account: %PlatformAccount{platform: :telegram, id: msg.from.id},
  #     body: context.update.message.text |> better_trim(),
  #     time: DateTime.from_unix!(msg.date),
  #     chat: %Chat{
  #       platform: :telegram,
  #       id: msg.chat.id,
  #       is_direct: msg.chat.type == "private"
  #     },
  #     # account:
  #     is_from_sue: false,
  #     is_ignorable: false,
  #     # attachments:
  #     has_attachments:
  #       Map.get(msg, :reply_to_message, %{})[:photo] != nil or
  #         Map.get(msg, :reply_to_message, %{})[:document] != nil,
  #     command: command,
  #     args: msg.text
  #   }
  # end

  def new(:telegram, %{msg: msg, context: context} = update) do
    Logger.info("NEW new called")

    {command, args, body} =
      case Map.get(update, :command) do
        nil -> command_args_from_body(:telegram, Map.get(msg, :caption, ""))
        c -> {c, msg.text, context.update.message.text}
      end

    command =
      parse_command_potentially_with_botname_suffix(command, "@" <> context.bot_info.username)

    %Message{
      platform: :telegram,
      id: msg.chat.id,
      platform_account: %PlatformAccount{platform: :telegram, id: msg.from.id},
      body: body |> better_trim(),
      time: DateTime.from_unix!(msg.date),
      chat: %Chat{
        platform: :telegram,
        id: msg.chat.id,
        is_direct: msg.chat.type == "private"
      },

      # we don't initialize handlers for non-command or sue messages
      is_from_sue: false,
      is_ignorable: false,

      # either in the message sent, or the message referenced in a reply
      has_attachments:
        Map.get(msg, :photo) != nil or
          Map.get(msg, :document) != nil or
          Map.get(msg, :reply_to_message, %{})[:photo] != nil or
          Map.get(msg, :reply_to_message, %{})[:document] != nil,
      command: command,
      args: args
    }
    |> construct_attachments(msg)
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

  def construct_attachments(%Message{has_attachments: false} = msg, _), do: msg

  def construct_attachments(%Message{platform: :telegram} = msg, data) do
    list_of_atts =
      Map.get(data, :photo) ||
        Map.get(data, :document) ||
        Map.get(data, :reply_to_message, %{})[:photo] ||
        Map.get(data, :reply_to_message, %{})[:document]

    list_of_atts =
      if is_map(list_of_atts) do
        [list_of_atts]
      else
        list_of_atts
      end

    %Message{
      msg
      | attachments:
          list_of_atts
          |> Enum.map(fn a -> Attachment.new(a, :telegram) end)
    }
  end

  # First stage of adding new fields to our Message. Primarily concerned with
  #   parsing commands, args, stripping whitespace.
  @spec augment_one(Message.t()) :: Message.t()

  defp augment_one(%Message{is_ignorable: true} = msg), do: msg

  defp augment_one(%Message{platform: :imessage} = msg) do
    "!" <> newbody = msg.body |> better_trim()
    parse_command(msg, newbody)
  end

  defp augment_one(%Message{platform: :telegram} = msg) do
    "/" <> newbody = msg.body |> better_trim()
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

  # TODO: Replace all of this with regular expressions.
  @spec command_args_from_body(Platform.t(), String.t()) :: {String.t(), String.t(), String.t()}
  defp command_args_from_body(:telegram, body) do
    "/" <> newbody = body |> better_trim()
    [command | args] = String.split(newbody, " ", parts: 2)
    {command, Enum.at(args, 0) || "", newbody}
  end

  # we'll use ! in debug as well
  defp command_args_from_body(_, body) do
    "!" <> newbody = body |> better_trim()
    [command | args] = String.split(newbody, " ", parts: 2)
    {command, Enum.at(args, 0) || "", newbody}
  end

  defp parse_command_potentially_with_botname_suffix(command, botname_suffix) do
    cond do
      String.ends_with?(command, botname_suffix) ->
        String.slice(command, 0, String.length(command) - String.length(botname_suffix))

      true ->
        command
    end
  end

  # character 65532 (OBJECT REPLACEMENT CHARACTER) is used in iMessage when you
  #   also have an image, like a fancy carriage return. trim_leading doesn't
  #   currently find this.
  defp better_trim_leading(text) when is_bitstring(text) do
    text
    |> String.replace_leading(List.to_string([65532]), "")
    |> String.trim_leading()
  end

  defp better_trim(text) do
    text
    |> better_trim_leading()
    |> String.trim()
  end

  # This binary classifier will grow in complexity over time.
  defp is_ignorable?(_platform, true, _body), do: true

  defp is_ignorable?(_platform, _from_me, nil), do: true

  defp is_ignorable?(:telegram, _from_me, body) do
    not Regex.match?(~r/^\/(?! )./u, body |> String.trim_leading())
  end

  defp is_ignorable?(platform, _from_me, body) when platform in [:imessage, :debug] do
    not Regex.match?(~r/^!(?! )./u, better_trim_leading(body))
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
