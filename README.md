# Sue
### A Chatbot for iMessage

Greetings, und willkommen to the lastest Inculi project— creating a chatbot for iMessage. In order to use Sue, it will have to be run on a Mac that has somewhat decent uptime. While most of the logic is in Python, it is interfaced with iMessage through an applescript handler that is set in iMessage's settings. You might want to make a new iCloud account to use with this (just sign into it in iMessage's settings). If you use your same iCloud account, you won't be able to send any commands— only your friends will.

**Note**: Due to the hacky nature of this interface, you will have to make sure that you do not use iMessage (on the same computer) while someone sends a command. If you are looking at the same group/chat that the command is sent in, the applescript routine runs `active chat message received` instead of `chat room message received`. I'll let you ask Apple why that is. You can have iMessage running in the background, just make sure it's not *the currently active application you are using*.

## Commands and Usage
- !8ball
- !choose <1> <2> ... <n>
- !define <word> <... meaning ...>
- !dirty
- !flip
- !fortune
- !identify <image>
- !img <... query ...>
- !lewd <image>
- !lunch
- !name <newname>
- !person <image>
- !poll <topic>\n<opt1>\n<opt2> ...
- !random <upper> <lower>
- !shuffle <1> <2> ... <n>
- !ud <... term ...>
- !uptime
- !vote <letter>
- !whoami
- !wiki <... topic ...>
- !wikis <... topic ...> , <... search filter ...>
- !wolf <... question ...>

## Setup

**Preface**: As this is still in alpha, I have not setup any build scripts or configuration/settings files. However, out of the kindness of my heart, I will explain how you can set this up for use (until I have the time to develop such things). You should know how to setup and install Mongo for this. If you don't, then you should know how to edit the Python code to remove the Mongo stuff.

`sue.applescript` is what is used to interface with iMessage. Open iMessage, and find the *applescript handler* dropdown. Select the *Open Folder* option, and move `sue.applescript` here. Close and reopen the preferences window, and select this as the new handler. Go ahead and open the script, and you should see the different actions that are taken when different kinds of messages are received. You will have to edit these to coincide with where you cloned this repository to.

Under: **`on message received theText from theBuddy with eventDescription`**  
- In the commandline, type `which python` to find where your python is. Replace `/usr/local/bin/python2` with what it tells you.  
- Still in the commandline, navigate to the location of where you cloned this repository, and type `pwd`. Replace `~/Documents/prog/Sue/` with what it tells you.
- Now, if you don't plan on making any changes to this, and you just want to use `a.py` and `b.py` for everything (thus ignoring `test.py` and `c.py`), go ahead and change `test.py` to `a.py`

Under: **`on chat room message received theText with eventDescription from theBuddy for theChat`**  
- do the same thing you did above.

If you changed `test.py` to `a.py`, then you only have to edit the suedir in `b.py` to reflect the path where you saved Sue. If you left `test.py`, make sure to change it in `c.py` as well.

Now, for Mongo. Create a new database called `sue`, and four collections: `images`, `defns`, `names`, `games`. Right now, only `defns` is being used, but the others will come shortly.

```bash
$ mongod # now make a new tab in terminal
$ mongo
> use sue
switched to db sue
> db.createCollection('images')
{ "ok" : 1 }
> db.createCollection('defns')
{ "ok" : 1 }
> db.createCollection('names')
{ "ok" : 1 }
> db.createCollection('games')
{ "ok" : 1 }
> show collections
defns
games
images
names
```
Excellent. It should work now.