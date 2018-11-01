from pprint import pprint, pformat
import random

import flask
import praw

from sue.models import Message

app = flask.current_app
bp = flask.Blueprint('webapis', __name__)

# TODO: Check to see if the user has specified Reddit API credentials.
reddit = None
def init_reddit():
    """We can't initialize this globally, as app.config hasn't loaded for some
    reason by the time we import webapis in __init__.py

    I'll look into it. It has something to do with app.app_context().
    """
    global reddit
    if not reddit:
        print('Initializing Reddit credentials')
        reddit = praw.Reddit(client_id=app.config['REDDIT_CLIENT_ID'],
                             client_secret=app.config['REDDIT_CLIENT_SECRET'],
                             user_agent=app.config['REDDIT_USER_AGENT'])

@bp.route('/wiki')
def wiki():
    """!wiki <... topic ...>
    
    Fetch the first 1-2 sentences of a wikipedia article.
    Usage: !wiki bill gates
    """
    import wikipedia as wikip

    msg = Message._create_message(flask.request.form)
    searchTerm = msg.textBody

    try:
        data = wikip.summary(searchTerm,sentences=1)
        if len(data) < 50:
            data = wikip.summary(searchTerm,sentences=2)
        return str(data)
    except:
        return "Hmm, couldn't find that..."

@bp.route('/wikis')
def wikis():
    """!wikis <... topic ...> , <... search filter ...>
    
    Extract sentences from a wikipedia article that pertain to a certain search
    filter.
    Usage: !wikis obama, president
    """
    import wikipedia as wikip
    msg = Message._create_message(flask.request.form)
    searchTerm = msg.textBody.split(',',1)

    if len(searchTerm) != 2:
        return ('Please separate the topic and search term with a comma.\
        \nEx: !wikis george washington, was born')

    from nltk.tokenize import sent_tokenize
    searchTerm = [x.lower().strip() for x in searchTerm]
    data = sent_tokenize(wikip.page(searchTerm[0]).content)
    data = [x for x in data if searchTerm[1] in x.lower()]
    data = data[:10] # we don't want too many sentences.
    if len(data) == 0:
        return 'No sentences match that...'
    for sent in data:
        return str(sent)

@bp.route('/wolf')
def wolf():
    """!wolf <... question ...>
    
    Query wolframalpha to answer certain questions.

    Usage: !wolf temperature in london on new years eve 2017
    """
    import wolframalpha

    responses = []

    msg = Message._create_message(flask.request.form)
    inputQuestion = msg.textBody

    client = wolframalpha.Client(app.config['WOLFRAM_KEY'])

    res = client.query(inputQuestion)

    if res.get('@error', 'true').lower() == 'true':
        # WA returned an error.
        return 'There was an error processing your query.'
    
    try:
        # no details data.
        results = res.details # dict-like
    except:
        results = {}

    inputInterp = dict()
    mainResult = dict()
    otherResults = []
    for key, val in results.items():
        if key == 'Input interpretation':
            inputInterp = { 'Input' : val }
        elif key == 'Result':
            mainResult = { key : val }
        else:
            if val:
                otherResults.append({ key : val })
            continue
    
    for item in [inputInterp, mainResult]:
        if item:
            responses.append(item)
    
    responses.extend(otherResults)
    responses = [('%s:\n%s\n' % tuple(x)[0]) for x in [y.items() for y in responses]]
    
    if responses:
        return responses
    
    # otherwise, there is some hidden data that made it escape the error.
    for key, val in res.items():
        if (key[0] != '@') and (key != 'assumptions'):
            responses.append(
                pformat({key : val}) + '\n'
            )
    
    if not responses:
        return 'WA did not give an error, but no useful data was found. Strange.'
    
    return responses

@bp.route('/ud')
def urbanDictionary():
    """!ud <... term ...>
    
    Query a phrase on urban dictionary.
    Usage: !ud meme
    """
    import sys
    import json
    import requests

    msg = Message._create_message(flask.request.form)
    term = msg.textBody

    responses = []

    if term:
        if sys.version < '3':
            from urllib import quote as urlquote
        else:
            from urllib.parse import quote as urlquote
        url = 'http://api.urbandictionary.com/v0/define?term=' + urlquote(term)
    else:
        # no term provided. Send a random one.
        url = 'http://api.urbandictionary.com/v0/random'

    r = requests.get(url)
    data = json.loads(r.content)
    if not data['list']:
        return ["Sorry, couldn't find that..."]
    
    clean = lambda x: x.replace('\r\n', '\n').strip()
    for entry in data['list'][:1]:
        responses.append(str(data['list'][0]['word']))
        output = 'def: ' + clean(entry['definition']) + '\n'
        output += 'ex: ' + clean(entry['example'])
        responses.append(str(output))
    
    return responses

@bp.route('/img')
def searchImage():
    """!img <... query ...>
    
    Query imgur.com to return a url to a related image (selects randomly from results).
    Usage: !img flower"""
    # use imgur's API to return the link to the first non-album result.
    from json import loads
    import random

    import requests

    msg = Message._create_message(flask.request.form)
    searchText = msg.textBody

    url = "https://api.imgur.com/3/gallery/search/{{sort}}/{{window}}/{{page}}"
    querystring = {"q":searchText}
    headers = {'authorization' : 'Client-ID 01aa1688f43ca6c'}
    response = requests.request("GET", url, headers=headers, params=querystring)

    a = loads(response.text)['data']
    # a = filter(lambda x: 'imgur.com/a/' not in x['link'], a)

    if len(a) > 0:
        try:
            return random.choice(a).get('link', 'Error selecting link from response...')
        except:
            # there was an error finding a link key in the item's dict.
            return "Sorry, I couldn't find a photo of that..."
    else:
        return "Sorry, I couldn't find a photo of that..."

@bp.route('/pasta')
def pasta():
    """!pasta

    Randomly send one of the top 5 posts on /r/copypasta at this moment.
    Usage: !pasta
    """
    init_reddit()
    topFivePosts = [*reddit.subreddit('copypasta').hot(limit=5)]
    return random.choice(topFivePosts).selftext