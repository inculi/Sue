import random
from pymongo import MongoClient
client = MongoClient('mongodb://localhost:27017')
db = client.games

"""In the games collection, it will be separated by group involved. Before
someone can send stuff to sue, they have to `!g join` in the grouptext. This is
to allow more than one game to go on at the same time.
"""

def game(sender,groupID,textBody):
    if len(textBody) < 1:
        print('Your available game options are:')
        print(' start <gameMode>\n end\n status\n')
        print('Your avilable gamemodes are:')
        listgames() # we'll define this later ;)
    
    else:
        textBody = textBody.split(' '.1)
        textBody[0] = textBody[0].lower()

        if textBody[0] == 'status':
            getGameStatus(groupID)
        elif textBody[0] == 'start':
            startGame(groupID,textBody[1])
        elif textBody[0] == 'end':
            endGame(groupID) # a group can only have one game going on.
        



{'poodletoes <id>' : {
    'gamemode' : 'nuclear',
    'players' : [],
    'sClass' : [],
    'sGood' : [],
    'sBad' : []
}}