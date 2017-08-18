import cPickle as pickle
import random
from pprint import pprint
import mongo # load our database interface from mongo.py
suedir = '/Users/lucifius/Documents/prog/Sue/'

# ==============================   Utilities   =================================

def clean(inputString):
    return inputString.strip().lower

# ============================   END Utilities   ===============================

def name(sender,command,textBody):
    """!name <newname>"""
    # make changes to our names collection.
    if len(textBody) == 0:
        print('Please specify a name.')
    else:
        mongo.updateName(sender,textBody)
        print(sender+' shall now be known as '+textBody)

def whoami(sender,command,textBody):
    """!whoami"""
    # load names from pickle file
    nameFound = mongo.findName(sender)

    if nameFound:
        print('You are '+ nameFound + '.')
    else:
        print('I do not know you. Set your name with !name')

# =======================   RANDOMIZATION FUNCTIONS   ==========================
def flip():
    """!flip"""
    print(random.choice(['heads','tails']))

def choose(textBody,sender):
    """!choose <1> <2> ... <n>"""
    options = textBody.split(' ')
    meguminOption = 'megumin' in map(lambda x: x.lower(), options)
    if meguminOption and sender == '12107485865':
        print('megumin')
    elif meguminOption and sender == '12108342408':
        print('http://megumin.club Roses are Red, Violets are Blue. Megumin best girl and glorious waifu.')
    else:
        print(random.choice(options))

def randomDist(textBody):
    """!random <lower> <upper>"""
    textBody = textBody.lower()
    randRange = sorted(textBody.split(' '))
    numberBased = set(map(lambda x: x.isdigit(), randRange))

    try:
        if numberBased == {True}:
            randRange = map(int, randRange)
            randRange.sort()
            print(int(round(random.uniform(randRange[0],randRange[1]))))
        elif numberBased == {False}:
            randRange = map(ord, randRange)
            randRange.sort()
            print(chr(int(round(random.uniform(randRange[0],randRange[1])))))
    except:
        print(random.random())

def shuffle(textBody):
    """!shuffle <1> <2> ... <n>"""
    items = textBody.split(' ')
    random.shuffle(items)
    print(reduce(lambda x,y: unicode(x)+' '+unicode(y), items))
# =====================   END RANDOMIZATION FUNCTIONS   ========================

# ===========================   USER DEFINITIONS   =============================
def define(textBody):
    """!define <word> <... meaning ...>"""
    if len(textBody) == 0:
        print('Please supply a word to define.')
        exit()
    try:
        textBody = textBody.split(' ',1)
        if len(textBody) == 2:
            defnName, meaning = textBody[0], textBody[1]
        else:
            print('Please supply a meaning for the word.')
    except:
        # There was an error.
        print('Error adding definition. No unicode pls :(')
        exit()

    defnName = clean(defnName)
    q = mongo.findDefn(defnName)
    if q:
        mongo.updateDefn(defnName, meaning)
        print(defnName + ' updated.')
    else:
        mongo.addDefn(defnName, meaning)
        print(defnName + ' added.')

def callDefn(defnName):
    q = mongo.findDefn(defnName)
    if q:
        print(q[u'meaning'].encode('utf-8'))
    else:
        print('Not found. Add it with !define')
# =========================   END USER DEFINITIONS   ===========================

def fortune():
    """!fortune"""
    import subprocess
    output = subprocess.check_output("/usr/local/bin/fortune", shell=True)
    print(output)

def dirty():
    """!dirty"""
    import subprocess
    output = subprocess.check_output("/usr/local/bin/fortune -o", shell=True)
    print(output)

def uptime():
    """!uptime"""
    import subprocess
    output = subprocess.check_output("uptime", shell=True)
    print(output)

# ==========================   IMAGE RECOGNITION   =============================
def identify(fileName):
    """!identify <image>"""
    print(fileName)
    if fileName == 'noFile':
        print('Please supply a file.')
    elif fileName == 'fileError':
        print('There was an error selecting the last file transfer.')
    else:
        from clarifai.rest import ClarifaiApp
        from clarifai.rest import Image as ClImage

        app = ClarifaiApp(api_key='ab4ea7efce5a4398bcbed8329a3d81c7')
        model = app.models.get('general-v1.3')
        image = ClImage(file_obj=open(fileName, 'rb'))

        imageData = model.predict([image])
        pprint(imageData)
        # imageData = imageData['outputs'][0]['data']['concepts'][:10]
        # imageData = map(lambda x: x['name'], imageData)
        # print(reduce(lambda x,y: x+', '+y, imageData))
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
    fortune,
    dirty,
    uptime,
    identify]

    for f in funcs:
        try:
            print(f.__doc__)
        except:
            pass

def sue(sender,command,textBody,fileName):
    if command == 'help':
        suehelp()
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
    elif command == 'fortune':
        fortune()
    elif command == 'dirty':
        dirty()
    elif command == 'uptime':
        uptime()
    elif command == 'identify':
        # print('Ice cream machine broken until I add image logging.')
        identify(fileName)
    else:
        try:
            callDefn(command)
        except:
            print('Command not found.')
