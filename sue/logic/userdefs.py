import flask

from sue.utils import clean, reduce_output
from sue.models import Message
import sue.db as db

app = flask.current_app
bp = flask.Blueprint('userdefs', __name__)

@bp.route('/define')
def define():
    """!define <word> <... meaning ...>"""
    msg = Message._create_message(flask.request.form)
    textBody = msg.textBody

    if len(textBody) == 0:
        return 'Please supply a word to define.'

    try:
        textBody = textBody.split(' ',1)
        if len(textBody) == 2:
            defnName, meaning = textBody[0], textBody[1]
        else:
            return 'Please supply a meaning for the word.'
    except:
        # There was an error.
        return 'Error adding definition. No unicode pls :('

    defnName = clean(defnName)
    q = db.findDefn(defnName)
    if q:
        db.updateDefn(defnName, meaning)
        return ('%s updated.' % defnName)
    else:
        db.addDefn(defnName, meaning)
        return ('%s added.' % defnName)

    return 0

@bp.route('/callDefn')
def callDefn():
    msg = Message._create_message(flask.request.form)
    defnName = msg.command

    q = db.findDefn(defnName)
    if q:
        return str(q[u'meaning'])
    else:
        return 'Not found. Add it with !define'

@bp.route('/phrases')
def phrases():
    import random

    data = db.listDefns()
    random.shuffle(data)

    output = reduce_output(data[0:30], delimiter=', ')

    return output

@bp.route('/name')
def name():
    """!name <newname>"""
    msg = Message._create_message(flask.request.form)
    sender = msg.sender
    textBody = msg.textBody
    # make changes to our names collection.
    if len(textBody) == 0:
        return 'Please specify a name.'
    else:
        db.updateName(sender,textBody)
        return '{0} shall now be known as {1}'.format(sender, textBody)

@bp.route('/whoami')
def whoami():
    """!whoami"""
    msg = Message._create_message(flask.request.form)
    sender = msg.sender
    # load names from pickle file
    nameFound = db.findName(sender)

    if nameFound:
        print('You are {0}.'.format(nameFound))
        return 'You are {0}.'.format(nameFound)
    else:
        return 'I do not know you. Set your name with !name'
