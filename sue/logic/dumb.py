import random

import flask
from sue.models import Message
from sue.utils import tokenize

app = flask.current_app
bp = flask.Blueprint('dumb', __name__)

@bp.route('/something')
def something():
    return 'Quit your crying, Nicko'

