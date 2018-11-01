# Sue
### A Chatbot for iMessage

Greetings, und willkommen to the lastest Inculi project— creating a chatbot for iMessage (and Signal).

To use Sue with iMessage, it will have to be run on a Mac that has somewhat decent uptime (Signal should work on whatever). While most of the logic is in Python, it is interfaced with iMessage through an applescript handler that is set in iMessage's settings. You *might* want to make a new iCloud account to use with this (just sign into it in iMessage's settings). If you use your same iCloud account, you won't be able to send any commands— only your friends will.

[Video Overview (YouTube)](https://www.youtube.com/watch?v=ocTAFPCH_A0)

## Commands

```
!8ball
!choose <1> <2> ... <n>
!define <word> <... meaning ...>
!dirty
!echo <... text ...>
!flip
!fortune
!i <param> <image>
!identify <image>
!img <... query ...>
!lewd <image>
!lunch
!name <newname>
!pasta
!person <image>
!poll <topic>\n<opt1>\n<opt2> ...
!qt
!random <upper> <lower>
!shuffle <1> <2> ... <n>
!ud <... term ...>
!uptime
!vote <letter>
!whoami
!wiki <... topic ...>
!wikis <... topic ...> , <... search filter ...>
!wolf <... question ...>
```

## Pre-Requisites for Installation

- If you want to use iMessage, it requires MacOS Sierra, as High Sierra removes the Applescript Handler.
- If you want to use Signal, you need Java.

**Note**: Apple's message handlers are a little... hacky. iMessage.app must be open, but its Window can't be in the foreground. If it's in the foreground, and the active chat you're looking at sends a message, it won't execute the script. If another chat other than the active chat sends a text, it will work, but then iMessage will switch to viewing that chat, and the next time they send something, it won't work. I'll let you ask Apple why that is.

Just open iMessage and then command+tab to the terminal window you launched it in and you'll be fine.

## Setup

**Preface**: As this is still in alpha, I have not setup any build scripts or configuration/settings files. However, out of the kindness of my heart, I will explain how you can set this up for use (until I have the time to develop such things). You should know how to setup and install Mongo for this. If you don't, then you should know how to edit the Python code to remove the Mongo stuff.

`sue.applescript` is what is used to interface with iMessage. Open iMessage's preferences, and find the *applescript handler* dropdown. Select the *Open Folder* option, and move `sue.applescript` here. Close and reopen the preferences window, and select this as the new handler.

Now, for Mongo. Create a new database called `sue`, and four collections: `images`, `defns`, `polls`, `names`, `games`. Right now, only `defns` and `polls` are being used, but the others will come shortly.

```bash
$ mongod # now make a new tab in terminal
$ mongo
> use sue
switched to db sue
> db.createCollection('polls')
{ "ok" : 1 }
> db.createCollection('defns')
{ "ok" : 1 }
# ... do the rest yourself ...
> show collections
defns
games
images
names
polls
```

- Go to this directory.
- `$ pip install -r requirements.txt`
- Create a `config.py` file, and copy the stuff in `example_config.py` to it. Change as needed.

Excellent. It should work now.

## Usage

- `$ python run.py`.
- If you're using signal, open a new tab, and `$ python run_signal.py`.
- If you want to test it out without using iMessage or signal, `$ python debug.py`

## Setup Part II
I'll put links here later about how to get the different API keys, but for now:

If you want to create a vote on where to eat lunch, you need to define a `lunchplaces` variable. You can do it with: `!define lunchplaces taco bell, fuego, subway`. Then, `!lunch` See the video at the top of this README for more info on the commands.