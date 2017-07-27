import cPickle as pickle
import random
from pprint import pprint
suedir = '/Users/lucifius/Documents/prog/Sue/'

def name(sender,command,textBody):
    """!name <newname>"""
    # load names from pickle file
    try:
        f = open(suedir+'names.pckl', 'rb')
        names = pickle.load(f)
        f.close()
    except IOError:
        names = {}

    # make changes
    if len(textBody) == 0:
        print('Please specify a name.')
    else:
        names[sender] = textBody
        print(sender+' shall now be known as '+textBody)

    # save changes
    f = open(suedir+'names.pckl', 'wb')
    pickle.dump(names, f)
    f.close()

def whoami(sender,command,textBody):
    """!whoami"""
    # load names from pickle file
    try:
        f = open(suedir+'names.pckl', 'rb')
        names = pickle.load(f)
        f.close()
    except IOError:
        names = {}

    nameFound = names[sender] if sender in names else None

    if nameFound:
        print('You are '+ nameFound + '.')
    else:
        print('I do not know you. Set your name with !name')

def flip():
    """!flip"""
    print(random.choice(['heads','tails']))

def choose(textBody):
    """!choose <1> <2> ... <n>"""
    print(random.choice(textBody.split(' ')))

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

def identify(fileName):
    """!identify <image>"""
    if fileName == 'noFile':
        print('Please supply a file.')
    else:
        from clarifai.rest import ClarifaiApp
        from clarifai.rest import Image as ClImage

        app = ClarifaiApp(api_key='ab4ea7efce5a4398bcbed8329a3d81c7')
        model = app.models.get('general-v1.3')
        image = ClImage(file_obj=open(fileName, 'rb'))

        imageData = model.predict([image])
        imageData = imageData['outputs'][0]['data']['concepts'][:10]
        imageData = map(lambda x: x['name'], imageData)
        print(reduce(lambda x,y: x+', '+y, imageData))

def suehelp():
    funcs = [
    name,
    whoami,
    flip,
    choose,
    randomDist,
    shuffle,
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
        choose(textBody)
    elif command == 'identify':
        identify(fileName)
    else:
        print('Command not found.')
