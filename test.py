# -*- coding: utf-8 -*-
import sys
from pprint import pprint

try:
    """ Note that:
    buddyId, chatId, inputText, fileName becomes
    sender, groupId, textBody, fileName. """
    data = sys.stdin.readlines()
    data = reduce(lambda x,y: unicode(x)+unicode(y), data)
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
    print('Most likely a unicode error with the reduce function.')
    exit()

if textBody.strip()[0] is not '!':
    # we aren't being called upon to do anything. Ignore the message.
    exit()
else:
    # find the command we are being told to do, and execute it.
    try:
        textBody = textBody.strip().replace('¬¬¬','"')
        command = textBody.split(' ',1)[0].replace('!','').lower()
        textBody = textBody.split(command,1)[1].strip()
    except:
        print('Error parsing: ==='+textBody+'===')
        exit()

    from c import sue
    sue(sender, groupId, command, textBody, fileName)
