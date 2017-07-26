import cPickle as pickle
import random
suedir = '/Users/lucifius/Documents/prog/Sue/'

def name(sender,command,textBody):
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
    print(random.choice(['heads','tails']))

def choose(textBody):
    print(random.choice(textBody.split(' ')))

def randomDist(textBody):
    try:
        randRange = map(int, textBody.split(' '))
        randRange.sort()
        print(int(round(random.uniform(randRange[0],randRange[1]))))
    except:
        pass

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
    else:
        print('Command not found.')
