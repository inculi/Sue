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
        sue_response = f()
        Response(flask.request.form, sue_response)
        return 'success'
    else:
        # see if it is user defined
        sue_response = sue_funcs['/callDefn']()
        Response(flask.request.form, sue_response)
        return 'success'

@bp.route('/help')
def sue_help():
    help_docs = []
    for r in app.url_map.iter_rules():
        current_doc = app.view_functions[r.endpoint].__doc__
        if current_doc and ('static' not in r.rule):
            help_docs.append(current_doc.strip())
    
    return reduce_output(sorted(help_docs), delimiter='\n')