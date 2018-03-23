# -*- coding: utf-8 -*-
import subprocess
import sys

import json
import re
import logging
from pprint import pprint

def sendReply(message):
    # print('handling reply')
    sender = message['envelope']['source']
    inputText = message['envelope']['dataMessage']['message']
    fileName = 'noFile' # I'll figure out where this is stored later

    groupInfo = message['envelope']['dataMessage']['groupInfo']
    groupId = 'singleUser'
    if groupInfo:
        groupId = groupInfo['groupId']

    print('---------')
    print(sender)
    print(inputText)
    # print('signal-'+groupId)
    # print(fileName)

    # call sue to examine the messageBody as per usual
    # print('sending to sue')
    text_reply = a_signal(sender, 'signal-'+groupId, inputText, fileName)
    if not text_reply:
        # print('Nothing to say')
        return None # nothing to say.
    # print('Done!')
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

def a_signal(sender, groupId, inputText, fileName):
    inputText = unicode(inputText).encode('utf-8')

    try:
        """ Note that:
        buddyId, chatId, inputText, fileName becomes
        sender, groupId, textBody, fileName. """


        if groupId != 'singleUser':
            if groupId[0:6] != 'signal':
                groupId = groupId.split('chat')[1]

        textBody = inputText
        fileName = fileName.replace('\n','')
    except:
        print('>.<')
        return None

    if len(textBody.strip()) == 0:
        # no text. Just a space.
        return None

    if textBody.strip()[0] is not '!':
        # we aren't being called upon to do anything. Ignore the message.
        return None
    else:
        # find the command we are being told to do, and execute it.
        # try:
        textBody = textBody.strip().replace('¬¬¬','"')
        command = textBody.split(' ',1)[0].replace('!','')
        if not command:
            return None
        textBody = textBody.split(command,1)[1].strip()
        # except:
        #     print('Error parsing: ==='+textBody+'===')
        #     exit()

        from b import sue
        # outString = "%s %s %s %s %s" % (sender, groupId, command.lower(), textBody, fileName)
        outString = sue(sender, groupId, command.lower(), textBody, fileName)
        return outString


def _handle_message(message):
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

    print('Starting...')
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stdin=subprocess.PIPE)

    for msg in iter(proc.stdout.readline, b''):
        msg = msg.decode('utf-8').strip()
        try:
            # the responses we will write back to the signal-cli process
            responses = []

            # read the message JSON
            msg = json.loads(msg)
            if msg.get('type') == 'message':
                # prepare the message for Sue's eyes.
                responses = _handle_message(msg)

            # write our responses back to the signal-cli
            for response in responses:
                try:
                    proc.stdin.write(response)
                except Exception as ex:
                    print('There was an error writing to stdin.')
                    print(ex)
                proc.stdin.write(b"\r\n")
                proc.stdin.flush()

        except Exception as ex:
            print('There was an error reading stdout.')
            print(ex)

BINARY = 'sue_signal/signal-cli/build/install/signal-cli/bin/signal-cli'
SIGNAL_NUMBER = '+12079560670'

run(BINARY, SIGNAL_NUMBER)