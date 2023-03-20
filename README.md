![](https://i.imgur.com/rEeXfKX.jpg)

# Sue

Greetings and welcome to Sue V3.1, a chatbot for iMessage and Telegram written in Elixir.

## Introduction

Sue has a long history. You'll have to ask me about it, because I'm not writing it. I made a [YouTube Video](https://www.youtube.com/watch?v=ocTAFPCH_A0) about an earlier version. Some things have been added since then, some things have been removed since then.

The following commands are currently supported:

```
!8ball
!choose
!cringe
!define
!doog
!flip
!fortune
!gpt
!motivate
!ping
!poll
!qt
!random
!uptime
!vote
```

Telegram uses the slash (/) prefix instead. Sue will not respond to you unless you use the proper prefix. **Do not just message her "hi", expecting a miracle**. You would be amazed how many people do.

## How do I run it?

Firstly, I aplogize. I used to use Elixir's built-in database, Mnesia, which was great because you didn't have to install anything. Sadly, I had to write many features myself and it has a 2GB storage limit, so I recently switched to [ArangoDB](https://www.arangodb.com/).


1. If you want to use iMessage, you need a mac with iMessage. You may be asked to enable disk access and Message control for this program (or, rather, Terminal/iTerm). I've been primarily testing this on Catalina, but it *should* work on older versions as well. I had some issues getting erlang's sqlite wrapper to compile on Sierra, but I think that was just my spaghetti system environment.
2. If you want to use Telegram, you should make a Telegram API key. Look up how, it's pretty straightforward. Make a `config/config.secret.exs` file, here is an example:

```elixir
import Config

# Telegram API
config :ex_gram, token: "mytoken"

config :desu_web, DesuWeb.Endpoint,
  secret_key_base: "Run this command: $ mix phx.gen.secret"

config :arangox,
  endpoints: "tcp://localhost:8529",
  username: "myuser",
  password: "mypass"

config :openai,
  api_key: "myapikey",
  http_options: [recv_timeout: 40_000]

```
3. If you wish to disable the Telegram or iMessage half of this program, modify the platform list under `config/config.exs` to what you wish to keep.
4. If you want to be able to use commands that write text atop images (currently only !motivate does this), you will need to install imagemagick with pango. If you already have imagemagick installed, you can run `$ convert -list format | grep -i pango` to see if you can at least read it. If you don't see `r--`, you can't read it and need to do the following: If you're on Mac, you're probably using homebrew, in which case you'll need to edit the install file (they removed pango because it depends on cairo which has many dependencies). After running `$ brew edit imagemagick`, you should be in an editor. Add a `depends_on "pango"` near its friends. Remove the `--without-pango`, adding a `--with-pango` near its friends. Save and quit. `$ brew reinstall imagemagick --build-from-source` (or `install` if you hadn't installed to begin with). Run that `-list format` command now and you should see it.
5. `$ git clone https://github.com/inculi/Sue`
6. `$ cd Sue`
7. `$ mix deps.get`
8. `$ MIX_ENV=prod mix release`
9. `$ Sue.post_init()`

Now it should be running in Elixir's interactive shell. If you don't know much about Elixir, welcome to the party. As Griffin, P. & Megumin (2019) often wrote, "The joke here is that the author is inviting you to join him in the set of programmers not especially well-versed in the language, while also hinting at the joyous future that awaits all students of Elixir."

## How do I add a command?

1. When Sue loads (see `sue.ex`), it iterates through a list of `@modules`, reading the methods defined in them. If a method name starts with `c_`, it is saved as a callable command. For example, see `rand.ex`:

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

Once you have modified your module, import it and place it in the `@modules` list at the top of `sue.ex`.

## How do I help contribute?

1. Submit an issue and I'll put together some instructions. Basically, just look at the tests. They do a good job of explaining most of Sue's major components, even if there isn't a test for everything.

## Known Issues

- Image functions do not work in Telegram. I think there's a new Telegram client for Elixir that I'll probably switch to.

## Special Thanks

- Thanks for [Zeke's](https://github.com/ZekeSnider) work on [Jared](https://github.com/ZekeSnider/Jared). Your applescript files were cleaner than mine. Good thinking with sqlite.
- [Peter's](https://github.com/reteps) work on [Otto](https://github.com/reteps/Otto), whose applescript handler was instrumental in Sue V1.
- Multiple bloggers who wrote about iMessage's sqlite schema.
- [Rick](https://github.com/rsrickshaw) for popping a shell in Sue V1, prompting the development of V2.
- All the random [people](https://github.com/Sam1370) that have messaged and broken Sue, pushing me ever forward in its development.