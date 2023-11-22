![](https://i.imgur.com/TIVNQ7o.jpg)

# Sue

Greetings and welcome to Sue, a chatbot for iMessage, Discord, and Telegram written in Elixir. Now with ChatGPT and Stable Diffusion!

## Demo

Feedback is greatly appreciated!

| Platform |                                 |
| ---------|---------------------------------|
| iMessage | send !help to sue@robertism.com |
| Telegram | send /help to @ImSueBot         |
| Discord  | send !help after [adding to your server](https://discord.com/api/oauth2/authorize?client_id=1087905317838409778&permissions=534723950656&scope=bot%20applications.commands) |

## Introduction

Sue has a long history. You'll have to ask me about it, because I'm not writing it. I made a [YouTube Video](https://www.youtube.com/watch?v=ocTAFPCH_A0) about an earlier version. Some things have been added since then, some things have been removed since then.

The following commands are currently supported:

```
!1984
!8ball
!box
!choose
!cringe
!define
!doog
!emoji
!flip
!fortune
!gpt
!gpt4
!motivate
!phrases
!ping
!poll
!qt
!random
!rub
!sd
!uptime
!vote
```

Telegram uses the slash (/) prefix instead. Sue will not respond to you unless you use the proper prefix. **Do not just message her "hi", expecting a miracle**. You would be amazed how many people do. Discord uses exclamation mark same as iMessage.

## How do I run it?

Firstly, I aplogize. I used to use Elixir's built-in database, Mnesia, which was great because you didn't have to install anything. Sadly, I had to write many features myself and it has a 2GB storage limit, so I recently switched to [ArangoDB](https://www.arangodb.com/).

1. If you want to use iMessage, you need a mac with iMessage. You may be asked to enable disk access and Message control for this program (or, rather, Terminal/iTerm). I've been primarily testing this on Catalina, but it *should* work on Monterrey and some older versions.
2. If you want to use Telegram, you should make a Telegram API key. Look up how, it's pretty straightforward. Similarly if you want to use ChatGPT, make an OpenAI account and generate an API key.
3. If you want to use Discord, again, make an API key, a bot, and under gateway intents enable message content intent.
4. If you wish to disable any platforms such as Telegram or iMessage, modify the platform list under `config/config.exs` to what you wish to keep.
5. If you want to be able to use commands that write text atop images (currently only !motivate does this), you will need to install imagemagick with pango. **If you don't care about this command, feel free to ignore the rest of this**. If you already have imagemagick installed, you can run `$ convert -list format | grep -i pango` to see if you can at least read it. If you don't see `r--`, you can't read it and need to do the following: If you're on Mac, you're probably using homebrew, in which case you'll need to edit the install file (they removed pango because it depends on cairo which has many dependencies). After running `$ brew edit imagemagick`, you should be in an editor. Add a `depends_on "pango"` near its friends. Remove the `--without-pango`, adding a `--with-pango` near its friends. Save and quit. `$ brew reinstall imagemagick --build-from-source` (or `install` if you hadn't installed to begin with). Run that `-list format` command now and you should see it.
6. [Download and install ArangoDB](https://www.arangodb.com/download-major/). Make a user account and remember the password. You'll later enter it in the config described below. Create three databases:

- subaru_test
- subaru_dev
- subaru_prod

Make sure the user you created has access to the databases. You can edit user permissions by being in the `_system` database, clicking the `Users` sidebar, selecting a user, then navigating to the `Permissions` tab.

7. `$ git clone https://github.com/inculi/Sue`
8. `$ cd Sue`
9. Make a `config/config.secret.exs` file, here is an example:

```elixir
import Config

# Telegram API
config :ex_gram, token: "mytoken"

# Discord API
config :nostrum,
  gateway_intents: [
    :guilds,
    :guild_messages,
    :guild_message_reactions,
    :direct_messages,
    :direct_message_reactions,
    :message_content
  ],
  token: "mytoken"

config :desu_web, DesuWeb.Endpoint,
  secret_key_base: "Run this command: $ mix phx.gen.secret"

config :arangox,
  endpoints: "tcp://localhost:8529",
  username: "myuser",
  password: "mypass"

config :openai,
  api_key: "myapikey",
  http_options: [recv_timeout: 40_000]

config :replicate,
  replicate_api_token: "myapikey"
```
10. Install Elixir if you don't already have it. I recommend using [asdf](https://asdf-vm.com/) to install.

```bash
# Use whatever version tag it recommends on the website:
# https://asdf-vm.com/guide/getting-started.html#official-download
# For me, this is:
$ git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1

# add ~/.asdf/bin to path

# Install erlang dependencies
# Discussed in https://github.com/asdf-vm/asdf-erlang
$ brew install autoconf openssl wxwidgets libxslt fop

# Add erlang and elixir plugins, install and set a version.
$ asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
$ asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
$ asdf install erlang 26.1.2
$ asdf install elixir 1.15.7
$ asdf global erlang 26.1.2
$ asdf global elixir 1.15.7

# add to path: ~/.asdf/shims
```

11. `$ mix deps.get`
12. To create a prod build, run `$ MIX_ENV=prod mix release` It should then tell you the path to the newly created executable.
13. To run in interactive dev mode, you can run `$ iex -S mix`.  If you want to Telegram to autocomplete your commands, run `Sue.post_init()` from within this interactive prompt. Sorry this part is a little scuffed.

## How do I add a command?

1. When Sue loads (see `sue.ex`), it iterates through the modules under `Sue.Commands`, reading the methods defined in them. If a method name starts with `c_`, it is saved as a callable command. For example, see `rand.ex`:

```elixir
@doc """
Flip a coin. Will return heads or tails.
Usage: !flip
"""
def c_flip(_msg) do
  %Response{body: ["heads", "tails"] |> Enum.random()}
end
```

If your command takes args, these are found in the Message's `args` field. Another example from rand:

```elixir
@doc """
Returns a random object in your space-delimited argument.
Usage: !choose up down left right
"""
def c_choose(%Message{args: ""}) do
  %Response{body: "Please provide a list of things to select. See !help choose"}
end

def c_choose(%Message{args: args}) do
  %Response{
    body:
      args
      |> String.split(" ")
      |> Enum.random()
  }
end
```

## How do I help contribute?

1. Submit an issue and I'll put together some instructions. Basically, just look at the tests. They do a good job of explaining most of Sue's major components, even if there isn't a test for everything.

## Known Issues

- Image functions stopped working in Telegram. I think there's a new Telegram client for Elixir that I'll probably switch to.

## Upgrading from Sue V3.0

Before you update to the new version, go to your current `mnesia/` directory and drill down to the final level where your .DAT files and what-not are stored. Move this last level directory to your project root directory and call it `mydir/` or something. Then create a new file called `export.exs` with this code:

```elixir
# export.exs
alias :mnesia, as: Mnesia

:ok = Mnesia.start([dir: String.to_charlist("mydir")])
:ok = Mnesia.wait_for_tables(Mnesia.system_info(:local_tables), 5_000)

record = {:edges, :_, :_, :_, :_, :_}
{:atomic, edges} = fn -> Mnesia.match_object(record) end |> Mnesia.transaction()
:file.write_file("edges.bin", :erlang.term_to_binary(edges))

{:atomic, defns} = fn -> Mnesia.match_object({:defn, :_, :_}) end |> Mnesia.transaction()
:file.write_file("defns.bin", :erlang.term_to_binary(defns))
```

Run it: `$ elixir export.exs`

This will generate two files (`edges.bin` and `defns.bin`). Update to the latest version of Sue, keeping these two new files and nothing else. Once you're in the new version of Sue, enter an interactive shell and perform the following:

```elixir
iex(1)> Sue.DB.import_mnesia_dump("path/to/edges.bin", "path/to/defns.bin")
```

There you go! I'm hoping this DB switch will be the last. Arango is pretty solid and should support all the future ideas I have for Sue + Desu + Kiku. Mnesia was neat, though.

## Special Thanks

- Thanks for [Zeke's](https://github.com/ZekeSnider) work on [Jared](https://github.com/ZekeSnider/Jared). Your applescript files were cleaner than mine. Good thinking with sqlite.
- [Peter's](https://github.com/reteps) work on [Otto](https://github.com/reteps/Otto), whose applescript handler was instrumental in Sue V1.
- Multiple bloggers who wrote about iMessage's sqlite schema.
- [Rick](https://github.com/rsrickshaw) for popping a shell in Sue V1, prompting the development of V2.
- All the random [people](https://github.com/Sam1370) that have messaged and broken Sue, pushing me ever forward in its development.