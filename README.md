![](https://i.imgur.com/rEeXfKX.jpg)

# Sue

Greetings and welcome to Sue V3, a chatbot for iMessage and Telegram. I'm sure portions of questionable stability exist, so please report any issues.

## What's New?

We have switched from Python to Elixir, from Applescript to Sqlite calls, from Mongo to Mnesia, from global user definitions to scoped user definitions. Because it's Elixir, some parts of the code look beautiful. Because I'm still a n00b at Elixir, some parts will scare you. I will refrain from making a [YouTube Video](https://www.youtube.com/watch?v=ocTAFPCH_A0) for V3 until I have more of it done.

The following commands are currently supported:

```
!8ball
!choose
!cringe
!define
!doog
!flip
!fortune
!motivate
!ping
!poll
!qt
!random
!uptime
!vote
```

Telegram uses the slash (/) prefix instead. Sue will not respond to you unless you use the proper prefix. Don't just message her "hi", expecting a miracle.

## How do I run it?

Again, it's still in development, so your Mnesia database may have to be cleared each update depending on what I change. If you're okay with that:

1. If you want to use iMessage, you need a mac with iMessage. You may be asked to enable disk access and Message control for this program (or, rather, Terminal/iTerm). I've been primarily testing this on Catalina, but it *should* work on older versions as well. I had some issues getting erlang's sqlite wrapper to compile on Sierra, but I think that was just my spaghetti system environment.
2. If you want to use Telegram, you should make a Telegram API key. Look up how, it's pretty straightforward. Make a `config/config.secret.exs` file, using `config/config.secret.exs.example` as reference.
3. If you wish to disable the Telegram or iMessage half of this program, modify the platform list under `config/config.exs` to what you wish to keep.
4. If you want to be able to use commands that write text atop images (currently only !motivate does this), you will need to install imagemagick with pango. If you already have imagemagick installed, you can run `$ convert -list format | grep -i pango` to see if you can at least read it. If you don't see `r--`, you can't read it and need to do the following: If you're on Mac, you're probably using homebrew, in which case you'll need to edit the install file (they removed pango because it depends on cairo which has many dependencies). After running `$ brew edit imagemagick`, you should be in an editor. Add a `depends_on "pango"` near its friends. Remove the `--without-pango`, adding a `--with-pango` near its friends. Save and quit. `$ brew reinstall imagemagick --build-from-source` (or `install` if you hadn't installed to begin with). Run that `-list format` command now and you should see it.
5. `$ git clone https://github.com/inculi/Sue`
6. `$ cd Sue`
7. `$ mix deps.get`
8. `$ iex -S mix`
9. `$ Sue.post_init()` I told you Telegram stuff was still half-finished, didn't I?

Now it should be running in Elixir's interactive shell. If you don't know much about Elixir, welcome to the party. As Griffin, P. & Megumin (2019) often wrote, "The joke here is that the author is inviting you to join him in the set of programmers not especially well-versed in the language, while also hinting at the joyous future that awaits all students of Elixir."



## How do I help contribute?

1. Submit an issue and I'll put together some instructions. Plugins are pretty simple: create a module under `lib/sue/commands/` and add its name to the top of `lib/sue.ex`

## Special Thanks

- Thanks for [Zeke's](https://github.com/ZekeSnider) work on [Jared](https://github.com/ZekeSnider/Jared). Your applescript files were cleaner than mine. Good thinking with sqlite.
- [Peter's](https://github.com/reteps) work on [Otto](https://github.com/reteps/Otto), whose applescript handler was instrumental in Sue V1.
- Multiple bloggers who wrote about iMessage's sqlite schema.
- [Rick](https://github.com/rsrickshaw) for popping a shell in Sue V1, prompting the development of V2.
- All the random [people](https://github.com/Sam1370) that have messaged and broken Sue, pushing me ever forward in its development.