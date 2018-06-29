import flask

from sue.models import Message, Response
from sue.utils import check_command, reduce_output

app = flask.current_app
bp = flask.Blueprint('main', __name__)

@bp.route('/')
def process_reply():
    if app.config['DEBUG']:
        print(flask.request.form)
    
    command = check_command(flask.request.form)
    if not command:
        return ''

    # get a list of our available functions
    sue_funcs = {}
    for r in app.url_map.iter_rules():
        sue_funcs[r.rule] = app.view_functions[r.endpoint]
    
    f = sue_funcs.get('/' + command)
    if f:
        # get the response back from Sue.
        sue_response = f()
    else:
        # see if it is user defined
        sue_response = sue_funcs['/callDefn']()

    # cast her response to a string. (ex: lists are reduced).
    if isinstance(sue_response, list):
        sue_response = reduce_output(sue_response, delimiter='\n')
    elif not isinstance(sue_response, str):
        try:
            sue_response = str(sue_response)
        except:
            sue_response = "Couldn't convert from {0} to str".format(
                type(sue_response))
    
    # message metadata will be used to direct response output.
    msg = Message._create_message(flask.request.form)

    if msg.platform is 'imessage':
        # forward to applescript handler
        Response(msg, sue_response)
        return 'success'
    elif msg.platform is 'signal':
        # return to GET request from run_signal.py
        return sue_response
    else:
        print('Unfamiliar message platform: {0}'.format(msg.platform))
        return 'failure'
    

@bp.route('/help')
def sue_help():
    help_docs = []
    for r in app.url_map.iter_rules():
        current_doc = app.view_functions[r.endpoint].__doc__
        if current_doc and ('static' not in r.rule):
            help_docs.append(current_doc.strip().split('\n')[0])
    
    return reduce_output(sorted(help_docs), delimiter='\n')