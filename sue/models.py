import subprocess
import sys
import os
from pprint import pprint

from urllib.parse import quote

from sue.utils import reduce_output

class Message(object):
    def __init__(self, msgForm):
        self.buddyId, self.chatId, self.textBody, self.fileName = (None,) * 4

    @classmethod
    def _create_message(cls, msgForm):
        textBody = msgForm['textBody'].strip()

        # find the command we are being told to execute
        cls.command = textBody.split(' ', 1)[0].replace('!', '').lower()

        # find the arguments for the command
        textBody = textBody.split(' ', 1)
        textBody = textBody[1].strip() if len(textBody) > 1 else ''

        # replace the unicode characters we changed in AppleScript back.
        cls.textBody = textBody.replace('¬¬¬', '$').replace('ƒƒƒ', '+')

        cls.chatId = msgForm['chatId'].replace('ƒƒƒ', '+')

        # use our chatId to infer the type of group chat we're in.
        if cls.chatId == 'singleUser':
            cls.chatType = 'imessage-individual'
        elif 'iMessage;+;' in cls.chatId:
            cls.chatType = 'imessage-group'
        elif cls.chatId == 'signal-singleUser':
            cls.chatType = 'signal-individual'
        elif 'signal-' in cls.chatId:
            cls.chatType = 'signal-group'
        else:
            cls.chatType = '?'

        cls.buddyId = msgForm['buddyId'].replace('ƒƒƒ', '+')

        # specify iMessage or signal as the platform
        if 'imessage' in cls.chatType:
            cls.platform = 'imessage'
        elif 'signal' in cls.chatType:
            cls.platform = 'signal'
        else:
            cls.platform = '?'

        # extract the phone number of the sender
        if cls.platform is 'imessage':
            sender = cls.buddyId.split(':',1)
            if len(sender) > 1:
                cls.sender = sender[1]
            else:
                print('There was an error extracting the sender info.')
                cls.sender = cls.buddyId
        elif cls.platform is 'signal':
            cls.sender = cls.buddyId
        else:
            cls.sender = '?'

        cls.fileName = msgForm['fileName'].replace('\n', '')

        return cls


class Response(object):
    def __init__(self, origin_message, sue_response):
        if origin_message.buddyId == 'debug':
            print('### DEBUG ###')
            pprint(sue_response)
        else:
            self.send_to_queue(origin_message, sue_response)

    def send_to_queue(self, origin_message, sue_response):
        FNULL = open(os.devnull, 'wb')

        origin_message.chatId = origin_message.chatId.replace(
            '+','ƒƒƒ').replace('$','¬¬¬')
        origin_message.buddyId = origin_message.buddyId.replace(
            '+','ƒƒƒ').replace('$','¬¬¬')
        
        command = ["osascript",
                   "direct.applescript",
                   quote(origin_message.chatId),
                   quote(origin_message.buddyId),
                   quote(sue_response)]
        print(command)

        print('Sending response.')
        subprocess.Popen(command, stdout=FNULL)

        FNULL.flush()
        FNULL.close()
