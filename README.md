# Sue

Greetings and welcome to Sue V3, a chatbot for iMessage (and soon also Telegram). The project is currently under renovation, though I hope to be done soonish.

## What's New?
We have switched from Python to Elixir, from Applescript to Sqlite calls, from Mongo to Mnesia, from global user definitions to scoped user definitions. Because it's Elixir, some parts of the code look beautiful. Because I'm still a n00b at Elixir, some parts will scare you. Sue's beauty has many dimensions... Two, to be precise.

I'll hold off on making another [YouTube Video](https://www.youtube.com/watch?v=ocTAFPCH_A0) for V3 until I have more of it done. I've been wanting an excuse to buy a new server, and now that I can finally run Sue on an OS newer than Sierra, I want to get this done quickly.

The following commands are currently supported:

```
!choose
!define
!doog
!flip
!fortune
!ping
!random
!uptime
```

## How do I run it?

Again, it's still in development, so your Mnesia database may have to be cleared each update depending on what I change. If you're okay with that:

1. You need a mac with iMessage. You may be asked to enable disk access and Message control for this program (or, rather, Terminal/iTerm). I've been primarily testing this on Catalina, but it *should* work on older versions as well. I had some issues getting erlang's sqlite wrapper to compile on Sierra, but I think that was just my spaghetti system environment.
2. `$ git clone https://github.com/inculi/Sue`
3. `$ cd Sue`
4. `$ mix deps.get`
5. `$ iex -S mix`

Now it should be running in Elixir's interactive shell. If you don't know much about Elixir, welcome to the party. As Griffin, P. & Megumin (2019) often wrote, "The joke here is that the author is inviting you to join him in the set of programmers not especially well-versed in the language, while also hinting at the joyous future that awaits all students of Elixir."

## How do I help contribute?

1. Submit an issue and I'll put together some instructions. Plugins are pretty simple: create a module under `lib/sue/commands/` and add its name to the top of `lib/sue.ex`

## Special Thanks

- Thanks for [Zeke's](https://github.com/ZekeSnider) work on [Jared](https://github.com/ZekeSnider/Jared). Your applescript files were cleaner than mine. Good thinking with sqlite.
- [Peter's](https://github.com/reteps) work on [Otto](https://github.com/reteps/Otto), whose applescript handler was instrumental in Sue V1.
- Multiple bloggers who wrote about iMessage's sqlite schema.
- [Rick](https://github.com/rsrickshaw) for popping a shell in Sue V1, prompting the development of V2.
- All the random [people](https://github.com/Sam1370) that have messaged and broken Sue, pushing me ever forward in its development.