import random

import flask
from sue.models import Message
from sue.utils import tokenize

app = flask.current_app
bp = flask.Blueprint('rand', __name__)

@bp.route('/flip')
def flip():
    """!flip
    
    Flip a coin. Will return heads or tails.
    Usage: !flip"""

    return random.choice(['heads','tails'])

@bp.route('/choose')
def choose():
    """!choose <1> <2> ... <n>
    
    Returns a random object in your space-delimited argument.
    Usage: !choose up down left right"""

    msg = Message._create_message(flask.request.form)
    options = tokenize(msg.textBody)

    meguminOption = ('megumin' in map(lambda x: x.lower(), options))
    if meguminOption and msg.sender == '+12107485865':
        return 'megumin'
    elif meguminOption and msg.sender == '+12108342408':
        return 'Roses are Red, Violets are Blue. Megumin best girl and glorious waifu.'
    else:
        return random.choice(options)

@bp.route('/random')
def sue_random():
    """!random <upper> <lower>
    
    Returns a random number between two positive integers.
    Usage: !random 1 10
    
    Return a random letter between two letters
    Usage: !random a z
    
    Return a random floating point number between 0 and 1 (0.47655569922929364)
    Usage: !random"""

    msg = Message._create_message(flask.request.form)

    if not msg:
        return 'Error with message.'

    textBody = msg.textBody.lower()

    print(textBody)

    randRange = sorted(textBody.split(' '))
    if len(randRange) != 2:
        # can't have a range between 3 elements
        return sue_random.__doc__

    numberBased = set(map(lambda x: x.isdigit(), randRange))

    try:
        if numberBased == {True}:
            # 1 - 123
            randRange = [int(x) for x in randRange]
            randRange.sort()
            return str(random.randint(randRange[0],randRange[1]))
        elif numberBased == {False}:
            # a - z
            randRange = [ord(x) for x in randRange]
            randRange.sort()
            return str(chr(random.randint(randRange[0],randRange[1])))
        else:
            return str(random.random())
    except:
        return str(random.random())

@bp.route('/shuffle')
def shuffle():
    """!shuffle <1> <2> ... <n>
    
    Shuffles and then returns your input."""
    from functools import reduce

    msg = Message._create_message(flask.request.form)
    
    items = tokenize(msg.textBody)
    random.shuffle(items)
    return reduce(lambda x,y: str(x)+' '+str(y), items)

@bp.route('/8ball')
def eightBall():
    """!8ball
    
    Ask it a question and it shall answer.
    Usage: !8ball will I die?"""
    
    possible_responses = [
        "As I see it, yes",
        "It is certain",
        "It is decidedly so",
        "Most likely",
        "Outlook good",
        "Signs point to yes",
        "Without a doubt",
        "Yes",
        "Yes - definitely",
        "You may rely on it",
        "Reply hazy, try again",
        "Ask again later",
        "Better not tell you now",
        "Cannot predict now",
        "Concentrate and ask again",
        "Don't count on it",
        "My reply is no",
        "My sources say no",
        "Outlook not so good",
        "Very doubtful"
    ]

    return random.choice(possible_responses)