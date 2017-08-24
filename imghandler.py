import requests
from pprint import pprint
import sys
import os

def downloadImage(imageUrl):
    if imageUrl:
        os.system('aria2c -q '+imageUrl+' -d ./images')
        fileName = imageUrl.rsplit('/',1)[1]
        return '~/Documents/prog/Sue/images/' + fileName
    else:
        print("Couldn't find that image.")
        return None

def sendImage(groupId, fileName):
    print(groupId)
    print(fileName)
    os.system('osascript direct.applescript {} {}'.format(groupId,fileName))

args = sys.argv[1:]
groupId = args[0]
fileName = args[1]

if 'http' in fileName:
    imgPath = downloadImage(fileName)
    if imgPath:
        sendImage(groupId, imgPath)
else:
    sendImage(groupId,fileName)
