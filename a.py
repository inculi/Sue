# -*- coding: utf-8 -*-
import sys
from pprint import pprint

try:
    data = sys.stdin.readlines()
    data = reduce(lambda x,y: unicode(x)+unicode(y), data)
    data = data.split('|~|',1)
    buddyID = data[0].rsplit('+',1)[1]
    textBody = data[1]
except:
    # There was some sort of error. I'll add logging later.
    exit()

if textBody.strip()[0] is not '!':
    # we aren't being called upon to do anything. Ignore the message.
    exit()
else:
    # find the command we are being told to do.
    textBody = textBody.strip().replace('¬¬¬','"')
    command = textBody.split(' ',1)[0].replace('!','').lower()
    textBody = textBody.split(command,1)[1].strip()

    from b import sue
    sue(buddyID, command, textBody)
