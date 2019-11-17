import subprocess
import sys
import os
from pprint import pprint

from sue.utils import reduce_output, secure_string

class Message(object):
    def __init__(self, msgForm):
        textBody = msgForm['textBody'].strip()

        # find the command we are being told to execute
        self.command = textBody.split(' ', 1)[0].replace('!', '').lower()

        # find the arguments for the command
        textBody = textBody.split(' ', 1)
        textBody = textBody[1].strip() if len(textBody) > 1 else ''

        # replace the unicode characters we changed in AppleScript back.
        self.textBody = textBody.replace('¬¬¬', '$').replace('ƒƒƒ', '+')

        self.chatId = msgForm['chatId'].replace('ƒƒƒ', '+')

        # use our chatId to infer the type of group chat we're in.
        if self.chatId == 'singleUser':
            self.chatType = 'imessage-individual'
        elif 'iMessage;+;' in self.chatId:
            self.chatType = 'imessage-group'
        elif self.chatId == 'signal-singleUser':
            self.chatType = 'signal-individual'
        elif 'signal-' in self.chatId:
            self.chatType = 'signal-group'
        elif self.chatId == 'debug':
            self.chatType = 'debug'
        else:
            self.chatType = '?'

        self.buddyId = msgForm['buddyId'].replace('ƒƒƒ', '+')

        # specify iMessage or signal as the platform
        if 'imessage' in self.chatType:
            self.platform = 'imessage'
        elif 'signal' in self.chatType:
            self.platform = 'signal'
        elif self.chatType == 'debug':
            self.platform = 'debug'
        else:
            self.platform = '?'

        # extract the phone number of the sender
        if self.platform is 'imessage':
            sender = self.buddyId.split(':',1)
            if len(sender) > 1:
                self.sender = sender[1]
            else:
                print('There was an error extracting the sender info.')
                self.sender = self.buddyId
        elif self.platform is 'signal':
            self.sender = self.buddyId
        else:
            self.sender = '?'

        self.fileName = msgForm['fileName'].replace('\n', '')


class IMessageResponse(object):
    """Base class used for sending Sue's response back to the user.

    Parameters
    ----------
    origin_message : Message
        The flask.request.form we have casted into a message. Contains info
          as to which group to send our response back to.
    sue_response : str
        All of our functions either return a string, or a list of strings that
          is then reduced (x+'\n'+y) back into a single string. This response
          string is what is sent back to the user.
    attachment : str
        The file path of any attachment we wish to send. We currently only
          support sending back files in iMessage. I plan on setting the message
          to an empty string ("") when there is an attachment, unless I find a
          scenario where I want to send an image and a string back.
    """
    def __init__(self, origin_message, sue_response, attachment=None):
        self.attachment = attachment
        if origin_message.buddyId == 'debug':
            print('### DEBUG ###')
            pprint(sue_response)
        else:
            self.send_to_queue(origin_message, sue_response)

    def send_to_queue(self, origin_message, sue_response):
        FNULL = open(os.devnull, 'wb')
        
        command = ["osascript",
                   "reply.applescript",
                   secure_string(origin_message.chatId),
                   secure_string(origin_message.buddyId),
                   secure_string(sue_response)]
        
        if self.attachment:
            f = secure_string(self.attachment)
            command.extend(['file', f])
        else:
            command.append('msg')
        
        print(command)

        print('Sending response.')
        subprocess.Popen(command, stdout=FNULL)

        FNULL.flush()
        FNULL.close()

class DirectResponse(object):
    def __init__(self, recipient, sue_response):
        self.send_to_queue(recipient, sue_response)
    
    def send_to_queue(self, recipient, sue_response):
        VIPs = {
            'robert' : ('+12107485865', 'phone'),
            'james'  : ('+12108603312', 'phone')
        }

         # detect if recipient is phoneNumber or iMessage email
        if '+' in recipient:
            method = 'phone'
        elif '@' in recipient:
            method = 'email'
        else:
            recipient, method = VIPs.get(recipient, (None, None))

        if not recipient:
            # still can't find it.
            print('Error matching recipient.')
            return

        FNULL = open(os.devnull, 'wb')
        
        # TODO: rename the applescript files to actually reflect what they do.
        command = ["osascript",
                   "replydirect.applescript",
                   secure_string(recipient),
                   secure_string(method),
                   secure_string(sue_response)]
        
        print(command)

        print('Sending response.')
        subprocess.Popen(command, stdout=FNULL)

        FNULL.flush()
        FNULL.close()

class DataResponse(object):
    """Used to pass attachments (images, etc.) as the output of functions.
    """
    def __init__(self, data):
        self.data = data