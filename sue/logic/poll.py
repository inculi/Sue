__credits__ = ["Jeff Hykin"]

from pprint import pprint

import flask

import sue.db as db
from sue.models import Message
from sue.utils import reduce_output, tokenize

app = flask.current_app
bp = flask.Blueprint('poll', __name__)

@bp.route('/poll')
def poll():
    """!poll <topic>\\n<opt1>\\n<opt2> ...
    
    Create a poll for people to !vote on.
    Usage: !poll which movie?
    grand budapest
    tron
    bee movie"""

    msg = Message(flask.request.form)
    options = tokenize(msg.textBody)

    if len(options) < 2:
        return 'Please specify a topic with options delimited by newlines.'

    if '?' in options[0]:
        # Injected user data may have messed up tokenization...
        # !poll Where should we have lunch? #lunchplaces (no comma)
        # instead of: !poll Where should we have lunch?, #lunchplaces (comma)

        firstQuestionIdx = options[0].find('?')
        if options[0][-1] != '?':
            # The question ended earlier in the string. Find it.
            pollQuestion, firstOption = options[0].split('?', 1)
            options = [pollQuestion.strip() + '?', firstOption.strip()] + options[1:]

    return create_poll(options, msg)

def create_poll(options, msg):
    """Allows !poll, !lunch, and eventually other commands to construct polls in
    a more abstracted way.
    """
    pprint(options)
    response = []
    
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
    """!vote <letter>
    
    Used to vote on a poll that is currently ongoing.
    Usage: !vote a"""

    msg = Message(flask.request.form)
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
        vote_plurality = 'vote' if (cnt == 1) else 'votes' # thanks, Rick :/
        response.append(
            '({0} {1}) {2}. {3}'.format(cnt, vote_plurality, ltr, option)
        )
    
    # mongo doesn't like sets so I have to convert to list.
    db.mUpdate('polls',
               {'group' : msg.chatId},
               {'group' : msg.chatId, 'data' : poll_data })
    
    return reduce_output(response, delimiter='\n')

@bp.route('/lunch')
def lunch():
    """!lunch
    
    Creates a poll to vote on a lunchplace, using the defn of !lunchplaces as \
    the input.
    """
    # we need the chatId for when we search the database...
    msg = Message(flask.request.form)

    # retrieve the group-specific lunchplaces
    places = db.findDefn('lunchplaces').get('meaning','')

    # if lunchPlaces isn't in the database
    if not places:
        return "Please !define lunchplaces <place1>, <place2>, ..."
    
    options = ["Where should we get lunch?"]
    options.extend([x.strip() for x in places.split(',')])

    return create_poll(options, msg)