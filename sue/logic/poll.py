__credits__ = ["Jeff Hykin"]

import flask

import sue.db as db
from sue.models import Message
from sue.utils import reduce_output

app = flask.current_app
bp = flask.Blueprint('poll', __name__)

@bp.route('/poll')
def poll():
    """!poll <topic>\\n<opt1>\\n<opt2> ..."""

    msg = Message._create_message(flask.request.form)
    options = msg.textBody.split('\n')

    response = []

    if len(options) < 2:
        return 'Please specify a topic with options delimited by newlines.'
    
    # set this to the current poll for our group.
    poll_data = {
        "letter_options" : [],
        "options" : options[1:],
        "question" : options[0],
        "votes" : {}
    }

    response.append(poll_data['question'])

    for i, cur_option in enumerate(poll_data["options"]):
        _option_letter = chr(ord('a') + i)
        poll_data["letter_options"].append(_option_letter)
        response.append("{0}. {1}".format(_option_letter, cur_option))
    
    db.mUpdate('polls',
               {'group' : msg.chatId},
               {'group' : msg.chatId, 'data' : poll_data })

    return reduce_output(response, delimiter='\n')

@bp.route('/vote')
def vote():
    """!vote <letter>"""

    msg = Message._create_message(flask.request.form)
    options = msg.textBody.split(' ')
    poll_data = db.mFind('polls', 'group', msg.chatId).get('data', {})

    if not poll_data:
        return 'Could not find a poll for your group. Make one with !poll'
    
    response = []

    # if there is actually a correct input
    if len(options) == 1:
        the_letter = options[0].lower()
        if the_letter in poll_data.get('letter_options', []):
            poll_data['votes'][msg.sender] = the_letter
        else:
            return 'That is not a option in this poll.'
    
    response.append(poll_data["question"])

    # display the new status
    total_letters = poll_data.get('letter_options')
    voted_letters = list(poll_data.get('votes', {}).values())
    vote_counts = [voted_letters.count(x) for x in total_letters]

    for cnt, ltr, option in zip(vote_counts, total_letters, poll_data['options']):
        # (0 votes) A. Dog
        response.append(
            '({0} votes) {1}. {2}'.format(cnt, ltr, option)
        )
    
    # mongo doesn't like sets so I have to convert to list.
    db.mUpdate('polls',
               {'group' : msg.chatId},
               {'group' : msg.chatId, 'data' : poll_data })
    
    return reduce_output(response, delimiter='\n')



@bp.route('/lunchPlaces')
def lunchPlaces():
    """!lunchPlaces <place1>, <place2>, ..."""

    msg = Message._create_message(flask.request.form)
    
    # split by commas and trim whitespace
    lunchPlaces = [each.strip() for each in msg.textBody.split(',')]

    # add lunchPlaces to the mongo polls collection 
    db.mUpdate('polls',
               {'group' : msg.chatId},
               {'group' : msg.chatId, 'lunchPlaces' : lunchPlaces })


@bp.route('/lunch')
def lunch():
    """!lunch"""

    # retrieve the group-specific lunchPlaces
    options = db.mFind('polls', 'group', msg.chatId).get('lunchPlaces', None)
    # if lunchPlaces isn't in the database
    if options == None:
        return "There are no lunchPlaces set,\nset with !lunchPlaces <place1>, <place2>, ..."
    options =  ["Where should we get lunch?"] + options
    msg = Message._create_message(flask.request.form)

    #
    # the rest of this code is copy-paste from !poll
    #
    response = []

    if len(options) < 2:
        return 'Please specify a topic with options delimited by newlines.'
    
    # set this to the current poll for our group.
    poll_data = {
        "letter_options" : set(),
        "options" : options[1:],
        "question" : options[0],
        "votes" : {}
    }

    response.append(poll_data['question'])

    for i, cur_option in enumerate(poll_data["options"]):
        _option_letter = chr(ord('a') + i)
        poll_data["letter_options"].add(_option_letter)
        response.append("{0}. {1}".format(_option_letter, cur_option))
    
    # mongo doesn't like sets so I have to convert to list.
    poll_data["letter_options"] = list(poll_data["letter_options"])
    db.mUpdate('polls',
               {'group' : msg.chatId},
               {'group' : msg.chatId, 'data' : poll_data })

    return reduce_output(response, delimiter='\n')