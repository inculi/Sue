import string
from pprint import pprint

from pymongo import MongoClient

client = MongoClient('mongodb://localhost:27017')
db = client.sue

def mFind(collection,key,value):
    q = db[collection].find_one({key : value})
    return q if q else {}

def mAdd(collection,item):
    db[collection].insert_one(item)

def mUpdate(collection,searchitem,updateitem):
    db[collection].update_one(searchitem, {'$set' : updateitem}, upsert=True)

### !define, user variables
def findDefn(defnName):
    q = db.defns.find_one({'name' : defnName.lower()})
    return q if q else {}

def addDefn(defnName, meaning):
    db.defns.insert_one({'name' : defnName, 'meaning' : meaning})

def updateDefn(defnName, meaning):
    db.defns.update_one({'name' : defnName},
                        {'$set' : {'meaning' : meaning}},
                        upsert=True)

def listDefns():
    return [item['name'] for item in db.defns.find({})]

def inject_user_structures(msg):
    # parse the msg.textBody for the variables we will replace with data

    # TODO: make the search scope first to defns the user has created themselves,
    #   and then to groups / other users they are associated with.
    text = msg.split(' ')
    for idx, word in enumerate(text):
        if len(word) < 2:
            # we run the risk of having a lone ' # '
            continue
        if word[0] == '#':
            # I originally was going to use this to filter out the commas,
            #   but then I realized we use !^ fairly often. Maybe I'll edit
            #   it later to just filter out commas, but we'll see...
            # wordToSearch = ''.join(
            #     [c for c in word if c not in string.punctuation])

            # for the variables we need to replace, look them up in the db
            text[idx] = findDefn(word[1:]).get('meaning', word)
    
    return ' '.join(text)

### !name, !whoami
def findName(phoneNumber):
    """searches for a given phone number in our names collection, and updates """
    q = db.names.find_one({'phoneNumber' : phoneNumber})

    if q:
        return q['name']
    else:
        return None

def updateName(phoneNumber,newName):
    db.names.update_one({'phoneNumber':phoneNumber}, {'$set' : {'name' : newName}}, upsert=True)
