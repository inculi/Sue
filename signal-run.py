# -*- coding: utf-8 -*-
import subprocess
import json
import re
import logging
from pprint import pprint

# from suesignal import sue_signal

def sue_signal(sender, groupId, inputText, fileName):
    """Functions somewhat like our applescript in that it prepares our message
    to be processed by sue
    """
    # inputText = inputText.replace('\"','¬¬¬')
    # print(inputText)
    command = 'echo \"%s|~|%s|~|%s|~|%s\" | python2 a.py' % (sender, groupId, inputText, fileName)

    output = subprocess.check_output(command, shell=True)
    return output

def sendReply(message):
    print('handling reply')
    sender = message['envelope']['source']
    inputText = message['envelope']['dataMessage']['message']
    fileName = 'noFile' # I'll figure out where this is stored later

    groupInfo = message['envelope']['dataMessage']['groupInfo']
    groupId = 'singleUser'
    if groupInfo:
        groupId = groupInfo['groupId']
    
    print(sender)
    print(inputText)
    print('signal-'+groupId)
    print(fileName)
    
    # call sue to examine the messageBody as per usual
    print('sending to sue')
    text_reply = sue_signal(sender, 'signal-'+groupId, inputText, fileName)
    if not text_reply:
        print('Nothing to say')
        return None # nothing to say.
    print('Done!')
    reply = {
        "type": "send",
        "messageBody": text_reply, # we'll set this when we know what it is
        "id": "1"
    }

    # reply = {
    #     "type": "send",
    #     "messageBody": "I heard you! >.<", # we'll set this when we know what it is
    #     "id": "1"
    # }

    if groupInfo:
        reply['recipientGroupId'] = groupId
    else:
        reply['recipientNumber'] = sender
    
    return reply


def _handle_message(message):
    print('handling message')
    responses = []
    if not message.get('envelope', {}).get('isReceipt', True):
        datamessage = message.get('envelope', {}).get('dataMessage', {})
        text = datamessage.get('message')
        group = datamessage.get('groupInfo')

        current_reply = sendReply(message)

        if current_reply:
            responses.append(json.dumps(current_reply))
    
    return responses

def run(signal_number, binary='signal-cli'):
    command = [binary, '-u', signal_number, 'jsonevtloop']
    # hooks = {"message": self._handle_message}

    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stdin=subprocess.PIPE)

    for msg in iter(proc.stdout.readline, b''):
        # pprint(msg)
        msg = msg.decode().strip()
        print(msg)

        try:
            responses = []

            msg = json.loads(msg)
            if msg.get('type') == 'message':
                responses = _handle_message(msg)

            for response in responses:
                print("Writing to signal-cli stdin: %s" % response)
                proc.stdin.write(response.encode('utf-8'))
                proc.stdin.write(b"\r\n")
                proc.stdin.flush()
        except:
            pass # invalid json


run('+12079560670', 'signal-cli/build/install/signal-cli/bin/signal-cli')
