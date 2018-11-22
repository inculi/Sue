from functools import reduce
from urllib.parse import quote

def check_command(msgForm):
    """
    Checks to make sure:
        1. we are actually being called to execute a command
        2. we have all the necessary parameters to execute it
        
    :param msgForm: a dictionary representing our GET request.
    :return: String of the command. Empty string if none exists.
    """

    # check to see the message contains all the information we require.
    required_keys = {'buddyId', 'chatId', 'textBody', 'fileName'}
    if len(set(msgForm.keys()) & required_keys) != 4:
        return ''

    textBody = msgForm['textBody'].strip()

    if len(textBody) == 0:
        # no text, just a space.
        return ''

    if textBody[0] is not '!':
        # we aren't being called upon to do anything. Ignore the message.
        return ''
    else:
        # find the command we are being told to execute, and execute it.
        command = textBody.split(' ', 1)[0].replace('!', '')
        if not command:
            # it was just exclamation marks
            return ''

    return command

def reduce_output(strList, delimiter=None):
    if delimiter:
        return reduce(lambda x,y: x+delimiter+y, strList)
    else:
        return reduce(lambda x,y: x+y, strList)

def secure_string(istr):
    return quote(istr.replace('+','ƒƒƒ').replace('$','¬¬¬'))

def clean(istr):
    return istr.strip().lower()

def tokenize(istr):
    """Used to parse lists of items in commands such as !choose and !poll
    """
    istr = istr.strip()

    if '\n' in istr:
        return istr.split('\n')
    elif ',' in istr:
        return [x.strip() for x in istr.split(',')]
    else:
        return istr.split(' ')
