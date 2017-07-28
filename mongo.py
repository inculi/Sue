from pymongo import MongoClient
from pprint import pprint
client = MongoClient('mongodb://localhost:27017')
db = client.sue

def clean(inputString):
    return inputString.strip().lower()

# ========================   INTERFACE WITH MONGODB   ==========================
def findDefn(defnName):
    q = db.defns.find_one({'name' : defnName})
    return q

def addDefn(defnName, meaning):
    db.defns.insert_one({'name' : defnName, 'meaning' : meaning})

def updateDefn(defnName, meaning):
    db.defns.update_one({'name' : defnName}, {'$set' : {'meaning' : meaning}})
# ======================   END INTERFACE WITH MONGODB   ========================
