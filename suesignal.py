# -*- coding: utf-8 -*-
import subprocess

def sue_signal(sender, groupId, inputText, fileName):
    """Functions somewhat like our applescript in that it prepares our message
    to be processed by sue
    """
    print('working!')
    inputText = inputText.replace('\"','¬¬¬')
    print(inputText)
    command = 'echo \"%s|~|%s|~|%s|~|%s\" | python a.py' % (sender, groupId, inputText, fileName)
    output = subprocess.check_output(command, shell=True)

    return output

# sue_signal('+12107485865', 'signal-gyUYJooIcd6MMV9Pn2mXUQ==', '!help', 'noFile')