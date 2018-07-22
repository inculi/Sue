from pprint import pprint, pformat

import flask
import requests
from requests.exceptions import ConnectionError

from sue.models import Message

app = flask.current_app
bp = flask.Blueprint('server', __name__)


def query_couch_potato(q):
    uri = 'http://localhost:5050/api/{0}/'.format(app.config['COUCH_POTATO_API'])

    try:
        data = requests.get(uri, data={'q' : q})
    except ConnectionError:
        return 'CouchPotato not installed, or service not up.'

    responses = []
    for movie in data.get('movies', []):
        imdb = movie.get('imdb')
        if imdb:
            imdb = '\nhttps://www.imdb.com/title/{2}/'.format(imdb)
        else:
            imdb = ''
        
        responses.append('{0} ({1}){2}\n'.format(
            movie.get('original_title', 'Unknown Title'),
            movie.get('year', '?'),
            imdb))
    
    return responses


@bp.route('/movie')
def movie():
    # Used to get information about movies that are currently being stored/
    #   downloaded.
    # TODO: Implement.
    # return 'Needs to be implemented.'
    msg = Message._create_message(flask.request.form)
    return query_couch_potato(msg.textBody)