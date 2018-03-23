import subprocess
import sys
import os
from pprint import pprint

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
        cls.textBody = textBody.replace('¬¬¬', '$')
        cls.textBody = textBody.replace('ƒƒƒ', '+')

        cls.chatId = msgForm['chatId']

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

        cls.buddyId = msgForm['buddyId']

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
    def __init__(self, flask_request, sue_response):
        origin_message = Message._create_message(flask_request)

        if isinstance(sue_response, list):
            sue_response = reduce_output(sue_response, delimiter='\n')
        elif not isinstance(sue_response, str):
            try:
                sue_response = str(sue_response)
            except:
                sue_response = "Couldn't convert from {0} to str".format(
                    type(sue_response))

        if origin_message.buddyId == 'debug':
            print('### DEBUG ###')
            pprint(sue_response)
        else:
            self.send_to_queue(origin_message, sue_response)

    def send_to_queue(self, origin_message, sue_response):
        FNULL = open(os.devnull, 'wb')
        command = ["osascript",
                   "direct.applescript",
                   origin_message.chatId,
                   origin_message.buddyId,
                   sue_response]
        
        print('Sending response.')
        subprocess.Popen(command, stdout=FNULL)

        FNULL.flush()
        FNULL.close()
