# -*- coding: utf-8 -*-
import sys
from pprint import pprint

try:
    """ Note that:
    buddyId, chatId, inputText, fileName becomes
    sender, groupId, textBody, fileName. """
    # data = sys.stdin.readlines()
    # data = reduce(lambda x,y: unicode(x)+unicode(y), data)

    data = sys.stdin.read()
    data = data.split('|~|')

    if len(data) != 4:
        # someone tried to mess up our data by adding a '|~|'
        print('Nice try, kid.')
        exit()
    sender = data[0].rsplit('+',1)[1]
    groupId = data[1]
    if groupId != 'singleUser':
        groupId = groupId.split('chat')[1]
    textBody = data[2]
    fileName = data[3].replace('\n','')
except:
    # There was some sort of error. I'll add logging later.
    quotes = [
    "Darkness blacker than black and darker than dark, I beseech thee, combine with my deep crimson. The time of awakening cometh. Justice, fallen upon the infallible boundary, appear now as an intangible distortion! Dance, Dance, Dance! I desire for my torrent of power a destructive force: a destructive force without equal! Return all creation to cinders, and come from the abyss!",
    "Oh, blackness shrouded in light Frenzied blaze clad in night In the name of the crimson demons, let the collapse of thine origin manifest. Summon before me the root of thy power hidden within the lands of the kingdom of demise!",
    "Crimson-black blaze, king of myriad worlds, though I promulgate the laws of nature, I am the alias of destruction incarnate in accordance with the principles of creation. Let the hammer of eternity descend unto me! ... Burn to ashes within the crimson.",
    "By my efflux of deep crimson, topple this white world!",
    "The tower of rebellion creeps upon man's world, The unspoken faith displayed before me, The time has come! Now, awaken from your slumber, and by my madness, be wrought!",
    "Detonation... Detonation... Detonation... Wielder of the most glorious, powerful, and grand explosion magic, My name is Megumin. The blow that I am given to strike turns a blind eye to the fate of my kindred, rendering all hope of rebirth and anguish, and the model by which all forces are judged! Pitiful creature... Synchronize yourself with the red smoke, and atone in a surge of blood!",
    "Roses are red, violets are blue. Megumin best girl and glorious waifu. http://megumin.club",
    "It was an explosion that brought this universe into existence. That explosion's name? Megumin. http://megumin.club",
    "Tautology: Aqua a shit."
    ]
    import random
    print(random.choice(quotes))
    exit()

if textBody.strip()[0] is not '!':
    # we aren't being called upon to do anything. Ignore the message.
    exit()
else:
    # find the command we are being told to do, and execute it.
    # try:
    textBody = textBody.strip().replace('¬¬¬','"')
    command = textBody.split(' ',1)[0].replace('!','')
    if not command:
        exit()
    textBody = textBody.split(command,1)[1].strip()
    # except:
    #     print('Error parsing: ==='+textBody+'===')
    #     exit()

    from c import sue
    sue(sender, groupId, command.lower(), textBody, fileName)
