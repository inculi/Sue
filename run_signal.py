import subprocess
import sys

import json
import re
import logging
from pprint import pprint

import requests

# global consts for running the signal server binary.
BINARY = 'sue_signal/signal-cli/build/install/signal-cli/bin/signal-cli'
SIGNAL_NUMBER = '+12079560670'

def _handle_message(message):
    responses = []

    sender = message['envelope']['source']
    groupInfo = message['envelope']['dataMessage']['groupInfo']
    groupId = 'signal-singleUser'
    if groupInfo:
        groupId = 'signal-{0}'.format(groupInfo['groupId'])
    
    # construct a GET data payload we can send to our flask server
    message_payload = {
        'textBody' : message['envelope']['dataMessage']['message'],
        'chatId' : groupId,
        'buddyId' : sender,
        'fileName' : 'noFile' # I'll figure out where this is stored later
    }

    print('---------')
    print(sender)
    print(message_payload['textBody'])

    r = requests.get('http://127.0.0.1:5000/', data=message_payload)
    if not r.content:
        return [] # no response from Sue.
    
    # json.dumps() requires string input, but proc.stdin requires bytes.
    # we will .encode('utf-8') before feeding it to the process.
    sue_reply = {
        "type": "send",
        "messageBody": r.content.decode('utf-8'),
        "id": "1"
    }

    if groupInfo:
        sue_reply['recipientGroupId'] = groupInfo['groupId']
    else:
        sue_reply['recipientNumber'] = sender
    
    return [json.dumps(sue_reply)]

def run(signal_number, binary='signal-cli'):
    command = [binary, '-u', signal_number, 'jsonevtloop']

    print('Starting...')
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stdin=subprocess.PIPE)

    # iterate over the json events it spits out to us.
    for msg in iter(proc.stdout.readline, b''):
        try:
            # the responses we will write back to the signal-cli process
            responses = []

            msg = json.loads(msg.decode('utf-8').strip())
            # pprint(msg) # uncomment when debugging :)

            if msg.get('type') == 'message':
                # only respond to jsonevents that are messages.
                if msg.get('envelope', {}).get('dataMessage'):
                    # prepare the message for Sue's eyes.
                    responses = _handle_message(msg)

            # write our responses back to the signal-cli
            for response in responses:
                try:
                    proc.stdin.write(response.encode('utf-8'))
                except Exception as ex:
                    print('There was an error writing to stdin.')
                    print(ex)
                proc.stdin.write(b"\r\n")
                proc.stdin.flush()

        except Exception as ex:
            print('There was an error reading stdout.')
            print(ex)

if __name__ == "__main__":
    # run server
    run(SIGNAL_NUMBER, BINARY)