# -*- coding: utf-8 -*-
import sys
from pprint import pprint

try:
    data = sys.stdin.readlines()
    pprint(data)
    data = reduce(lambda x,y: unicode(x)+unicode(y), data)
    data = data.split('|~|')
    buddyID = data[0].rsplit('+',1)[1]
    textBody = data[1]
    fileName = data[2].replace('\n','')
except:
    # There was some sort of error. I'll add logging later.
    exit()

if textBody.strip()[0] is not '!':
    # we aren't being called upon to do anything. Ignore the message.
    exit()
else:
    # find the command we are being told to do.
    try:
        textBody = textBody.strip().replace('¬¬¬','"')
        command = textBody.split(' ',1)[0].replace('!','')
        textBody = textBody.split(command,1)[1].strip()
    except:
        print('Error parsing: ==='+textBody+'===')
        exit()

    from c import sue
    sue(buddyID, command.lower(), textBody, fileName)
