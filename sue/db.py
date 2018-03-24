from pymongo import MongoClient
from pprint import pprint
client = MongoClient('mongodb://localhost:27017')
db = client.sue

def mFind(collection,key,value):
    q = db[collection].find_one({key : value})
    return q if q else {}

def mAdd(collection,item):
    db[collection].insert_one(item)

def mUpdate(collection,searchitem,updateitem):
    db[collection].update_one(searchitem, {'$set' : updateitem}, upsert=True)

### !DEFINE
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

### !NAME, !WHOAMI
def findName(phoneNumber):
    """searches for a given phone number in our names collection, and updates """
    q = db.names.find_one({'phoneNumber' : phoneNumber})

    if q:
        return q['name']
    else:
        return None

def updateName(phoneNumber,newName):
    db.names.update_one({'phoneNumber':phoneNumber}, {'$set' : {'name' : newName}}, upsert=True)
