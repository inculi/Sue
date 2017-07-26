import cPickle as pickle
import random
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
    """!random <lowerbound> <upperbound>"""
    try:
        randRange = map(int, textBody.split(' '))
        randRange.sort()
        print(int(round(random.uniform(randRange[0],randRange[1]))))
    except:
        pass

def help():
    funcs = [
    name,
    whoami,
    flip,
    choose,
    randomDist]

    for f in funcs:
        print(f.__doc__)


def sue(sender,command,textBody):
    command = command.lower()
    if command == 'name':
        name(sender, command, textBody)
    elif command == 'whoami':
        whoami(sender, command, textBody)
    elif command == 'flip':
        flip()
    elif command == 'random':
        randomDist(textBody)
    elif command == 'choose':
        choose(textBody)
    elif command == 'help':
        help()
    else:
        print('Command not found.')

help()
