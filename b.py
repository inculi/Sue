import cPickle as pickle
import random
from pprint import pprint
import os
import mongo # load our database interface from mongo.py
import sys
suedir = '/Users/lucifius/Documents/prog/Sue/'


# RESPONSES = []


# ==============================   Utilities   =================================

def clean(inputString):
    return inputString.strip().lower()

def rprint(inputString, newLine=True):
    if newLine:
        RESPONSES.append(unicode(inputString+'\n'))
    else:
        RESPONSES.append(unicode(inputString))

def stdprint(inputString):
    sys.stdout.write(inputString)

# ============================   END Utilities   ===============================

def name(sender,command,textBody):
    """!name <newname>"""

    # make changes to our names collection.
    if len(textBody) == 0:
        rprint('Please specify a name.')
    else:
        mongo.updateName(sender,textBody)
        rprint(sender+' shall now be known as '+textBody)

def whoami(sender,command,textBody):
    """!whoami"""

    # load names from pickle file
    nameFound = mongo.findName(sender)

    if nameFound:
        rprint('You are '+ nameFound + '.')
    else:
        rprint('I do not know you. Set your name with !name')

# =======================   RANDOMIZATION FUNCTIONS   ==========================
def flip():
    """!flip"""

    rprint(random.choice(['heads','tails']))

def choose(textBody,sender):
    """!choose <1> <2> ... <n>"""

    options = textBody.split(' ')
    meguminOption = 'megumin' in map(lambda x: x.lower(), options)
    if meguminOption and sender == '12107485865':
        rprint('megumin')
    elif meguminOption and sender == '12108342408':
        rprint('http://megumin.club Roses are Red, Violets are Blue. Megumin best girl and glorious waifu.')
    else:
        rprint(random.choice(options))

def randomDist(textBody):
    """!random <lower> <upper>"""
    textBody = textBody.lower()
    randRange = sorted(textBody.split(' '))
    numberBased = set(map(lambda x: x.isdigit(), randRange))

    try:
        if numberBased == {True}:
            randRange = map(int, randRange)
            randRange.sort()
            rprint(int(round(random.uniform(randRange[0],randRange[1]))))
        elif numberBased == {False}:
            randRange = map(ord, randRange)
            randRange.sort()
            rprint(chr(int(round(random.uniform(randRange[0],randRange[1])))))
    except:
        rprint(random.random())

def shuffle(textBody):
    """!shuffle <1> <2> ... <n>"""
    items = textBody.split(' ')
    random.shuffle(items)
    rprint(reduce(lambda x,y: unicode(x)+' '+unicode(y), items))
# =====================   END RANDOMIZATION FUNCTIONS   ========================

# ===========================   USER DEFINITIONS   =============================
def define(textBody):
    """!define <word> <... meaning ...>"""
    if len(textBody) == 0:
        rprint('Please supply a word to define.')
        return 1

    try:
        textBody = textBody.split(' ',1)
        if len(textBody) == 2:
            defnName, meaning = textBody[0], textBody[1]
        else:
            rprint('Please supply a meaning for the word.')
            return 1
    except:
        # There was an error.
        rprint('Error adding definition. No unicode pls :(')
        return 1

    defnName = clean(defnName)
    q = mongo.findDefn(defnName)
    if q:
        mongo.updateDefn(defnName, meaning)
        rprint(defnName + ' updated.')
    else:
        mongo.addDefn(defnName, meaning)
        rprint(defnName + ' added.')

    return 0

def phrases():
    data = mongo.listDefns()
    random.shuffle(data)

    output = ''
    for x in data[0:30]:
        output += (x + ', ')
    output += data[30]

    rprint(output.encode('utf-8'))

def callDefn(defnName):
    q = mongo.findDefn(defnName)
    if q:
        rprint(q[u'meaning'].encode('utf-8'))
    else:
        rprint('Not found. Add it with !define')
# =========================   END USER DEFINITIONS   ===========================

def fortune():
    """!fortune"""
    import subprocess
    output = subprocess.check_output("/usr/local/bin/fortune", shell=True)
    rprint(output)

def dirty():
    """!dirty"""
    import subprocess
    output = subprocess.check_output("/usr/local/bin/fortune -o", shell=True)
    rprint(output)

def uptime():
    """!uptime"""
    import subprocess
    output = subprocess.check_output("uptime", shell=True)
    rprint(output)

def wiki(searchTerm):
    """!wiki <... topic ...>"""
    import wikipedia as wikip

    try:
        data = wikip.summary(searchTerm,sentences=1)
        if len(data) < 50:
            data = wikip.summary(searchTerm,sentences=2)

        rprint(data.encode('utf-8'))
    except:
        rprint("Hmm, couldn't find that...")

def wikis(searchTerm):
    """!wiki <... topic ...> , <... search filter ...>"""
    import wikipedia as wikip
    searchTerm = searchTerm.split(',',1)

    if len(searchTerm) != 2:
        rprint('Please separate the topic and search term with a comma.\
        \nEx: !wikis george washington, was born')
        return

    from nltk.tokenize import sent_tokenize
    searchTerm = [x.lower().strip() for x in searchTerm]
    data = sent_tokenize(wikip.page(searchTerm[0]).content)
    data = [x for x in data if searchTerm[1] in x.lower()]
    data = data[:10] # we don't want too many sentences.
    if len(data) == 0:
        rprint('No sentences match that...')
        return
    for sent in data:
        rprint(sent.encode('utf-8'))

    # try:
    #     from nltk.tokenize import sent_tokenize
    #     searchTerm = [x.lower().strip() for x in searchTerm]
    #     data = sent_tokenize(wikip.page(searchTerm[0]).content)
    #     data = [x for x in data if searchTerm[1] in x.lower()]
    #     data = data[:10] # we don't want too many sentences.
    #     for sent in data:
    #         print(sent.encode('utf-8'))
    # except ImportError:
    #     print("Please pip install nltk first.")
    # except:
    #     print("Hmm, couldn't find that...")


def wolf(inputQuestion):
    """!wolf <... question ...>"""
    import wolframalpha
    client = wolframalpha.Client('HWP8QY-EL2KR2KKLW')

    res = client.query(inputQuestion)

    interp = [pod for pod in res.pods if pod['@title'] == 'Input interpretation']
    results = [pod for pod in res.pods if pod['@title'] == 'Result']

    # TODO: "integral of sigmoid function" returns empty interp and results.
    #       there are more things that still need extraction.

    if interp:
        rprint('Input:')
        for item in interp:
            try:
                print(item['subpod']['img']['@alt'])
            except:
                pass # didn't have the right keys.
        rprint('\nResult:')

    # TODO: if results is empty, the answer was in image form. extract that.
    for res in results:
        try:
            rprint(res['subpod']['img']['@alt'])
        except:
            pass # didn't have the right keys.

def urbanDictionary(term):
    """!ud <... term ...>"""
    import sys
    import json
    import requests

    if term:
        if sys.version < '3':
            from urllib import quote as urlquote
        else:
            from urllib.parse import quote as urlquote
        url = 'http://api.urbandictionary.com/v0/define?term=' + urlquote(term)
    else:
        # no term provided. Send a random one.
        url = 'http://api.urbandictionary.com/v0/random'

    r = requests.get(url)
    data = json.loads(r.content)
    if not data['list']:
        rprint("Sorry, couldn't find that...")

    clean = lambda x: x.replace('\r\n', '\n').strip()
    rprint((data['list'][0]['word']).encode('utf-8'))
    for entry in data['list'][:1]:
        output = 'def: ' + clean(entry['definition']) + '\n'
        output += 'ex: ' + clean(entry['example'])
        rprint(output.encode('utf-8'))

def searchImage(searchText):
    """!img <... query ...>"""
    # use imgur's API to return the link to the first non-album result.
    from json import loads
    import requests
    url = "https://api.imgur.com/3/gallery/search/{{sort}}/{{window}}/{{page}}"
    querystring = {"q":searchText}
    headers = {'authorization': 'Client-ID 01aa1688f43ca6c'}
    response = requests.request("GET", url, headers=headers, params=querystring)

    a = loads(response.text)['data']
    # a = filter(lambda x: 'imgur.com/a/' not in x['link'], a)

    if len(a) > 0:
        # imageUrl = a[0]['link']
        # return random.choice(a)['link']
        try:
            return random.choice(a)['link']
        except:
            # there was an error finding a link key in the item's dict.
            return None
    else:
        return None

# ============================   DOES NOT WORK   ===============================
# TODO: Make this actually work
def downloadImage(imageUrl):
    os.system('aria2c -q '+imageUrl+' -d ./images')
    fileName = imageUrl.rsplit('/',1)[1]
    return './images/' + fileName # return the filePath to the image.

# TODO: Make this actually work.
def sendImage(groupId, fileName):
    os.system('osascript direct.applescript {} {}'.format(groupId, fileName))

# TODO: Make this actually work.
def imgHandler(groupId,imageInfo):
    """imageInfo could be either a link you want to download and then send,
    or a fileName you just want to send."""

    if 'http' in imageInfo:
        imgPath = downloadImage(imageInfo)
        if imgPath:
            sendImage(groupId, imgPath)
    else:
        sendImage(groupId,imageInfo)
# ==========================   END DOES NOT WORK   =============================


def img(groupId,textBody):
    imgUrl = searchImage(textBody)

    if imgUrl:
        rprint(imgUrl, newLine=False)
    else:
        rprint('Sorry, I could not find a photo of that...')

    # imgHandler(groupId,imgUrl)

# ==========================   IMAGE RECOGNITION   =============================
def identify(fileName):
    """!identify <image>"""
    # print(fileName)
    if fileName == 'noFile':
        rprint('Please supply a file.')
    elif fileName == 'fileError':
        rprint('There was an error selecting the last file transfer.')
    else:
        from clarifai.rest import ClarifaiApp
        from clarifai.rest import Image as ClImage

        app = ClarifaiApp(api_key='ab4ea7efce5a4398bcbed8329a3d81c7')
        model = app.models.get('general-v1.3')
        image = ClImage(file_obj=open(fileName, 'rb'))

        imageData = model.predict([image])
        try:
            imageData = imageData['outputs'][0]['data']['concepts'][:10]
            imageData = map(lambda x: x['name'], imageData)
            rprint(reduce(lambda x,y: x+', '+y, imageData))
        except:
            rprint('Error, most likely with the reduce function. Unicode maybe?')
# ========================   END IMAGE RECOGNITION   ===========================

def suehelp():
    funcs = [
    name,
    whoami,
    flip,
    choose,
    randomDist,
    shuffle,
    define,
    wiki,
    wolf,
    urbanDictionary,
    searchImage,
    fortune,
    dirty,
    uptime,
    identify]

    for f in funcs:
        try:
            rprint(f.__doc__)
        except:
            pass

def sue(sender,groupId,command,textBody,fileName):
    global RESPONSES
    RESPONSES = []

    if command == 'help':
        suehelp()
    elif command == 'groupId':
        rprint('The id for this group is:')
        rprint(groupId)
    elif command == 'name':
        name(sender, command, textBody)
    elif command == 'whoami':
        whoami(sender, command, textBody)
    elif command == 'flip':
        flip()
    elif command == 'random':
        randomDist(textBody)
    elif command == 'shuffle':
        shuffle(textBody)
    elif command == 'choose':
        choose(textBody,sender)
    elif command == 'define':
        define(textBody)
    elif command == 'phrases':
        phrases()
    elif command == 'wiki':
        wiki(textBody)
    elif command == 'wikis':
        wikis(textBody)
    elif command == 'wolf':
        wolf(textBody)
    elif command == 'ud':
        urbanDictionary(textBody)
    elif command == 'fortune':
        fortune()
    elif command == 'dirty':
        dirty()
    elif command == 'uptime':
        uptime()
    elif command == 'img':
        img(groupId,textBody)
    elif command == 'identify':
        # print('Ice cream machine broken until I add image logging.')
        identify(fileName)
    else:
        try:
            callDefn(command)
        except:
            rprint('Command not found.')

    if groupId[0:6] == 'signal':
        # print('signal!')
        outString = u''
        for response in RESPONSES:
            outString += unicode(response)
        RESPONSES = []
        return outString
    else:
        for response in RESPONSES:
            stdprint(response)
