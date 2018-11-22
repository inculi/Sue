from pprint import pprint
import json

import flask
from werkzeug import ImmutableMultiDict

from sue.models import Message, Response, DataResponse
from sue.utils import check_command, reduce_output
from sue.db import inject_user_structures

app = flask.current_app
bp = flask.Blueprint('main', __name__)

@bp.route('/')
def process_reply():
    """Main route for processing requests.
    
    Based on information we detect in the flask.request.form (logic provided
      in models.py), we can figure out if we are sending the response back to
      Signal, iMessage, and from there-- a group, or an individual. Cool, huh?
    """

    if app.config['DEBUG']:
        pprint(flask.request.form)
    
    command = check_command(flask.request.form)
    if not command:
        # User isn't talking to Sue. Ignore.
        return ''
    
    # message metadata will be used to direct response output.
    msg = Message(flask.request.form)

    # parse message textBody to see if we need to inject any user-defined
    # variables into it.
    if msg.textBody:
        newFormItems = []
        for key, val in flask.request.form.to_dict().items():
            if key == 'textBody':
                # inject our variables into it.
                if '#' in val:
                    newTextBody = inject_user_structures(val)
                    newFormItems.append((key, newTextBody))
                    continue

            newFormItems.append((key,val))
        flask.request.form = ImmutableMultiDict(newFormItems)
    
    print(flask.request.form)
    # get a list of our available functions
    sue_funcs = {}
    for r in app.url_map.iter_rules():
        sue_funcs[r.rule] = app.view_functions[r.endpoint]
    
    f = sue_funcs.get('/' + command)
    if f:
        # Command exists. Execute it and get the response.
        sue_response = f()
    else:
        # It's not a command we made. Check to see if it is user defined.
        sue_response = sue_funcs['/callDefn']()

    # cast her response to a string. (ex: lists are reduced).
    attachment = None
    if isinstance(sue_response, list):
        sue_response = reduce_output(sue_response, delimiter='\n')
    elif isinstance(sue_response, DataResponse):
        # set the attachment to our image path
        attachment = sue_response.data

        # set the sue_response to a blank string (we won't send it anyway)
        sue_response = ''
    elif not isinstance(sue_response, str):
        try:
            sue_response = str(sue_response)
        except:
            sue_response = "Couldn't convert from {0} to str".format(
                type(sue_response))

    # TODO: Create consts for these, so we have less `magic string` usage.
    if msg.platform is 'imessage':
        # forward to applescript handler
        IMessageResponse(msg, sue_response, attachment=attachment)
        return 'success'
    elif msg.platform is 'signal':
        # return to GET request from run_signal.py
        return json.dumps({
            'messageBody': sue_response,
            'attachmentFilenames': [attachment]
        })
    elif msg.platform is 'debug':
        return 'SUE :\n{0}'.format(sue_response)
    else:
        print('Unfamiliar message platform: {0}'.format(msg.platform))
        # TODO: Throw exception?
        return 'failure'
    
@bp.route('/echo')
def echo():
    """!echo <... text ...>
    
    Used to debug member-defined data structures.
    You: !echo !choose #lunchplaces
    Sue: !choose fuego, antonios, potbelly, taco bell"""
    msg = Message(flask.request.form)
    return msg.textBody

@bp.route('/help')
def sue_help():
    """Returns a sorted list of commands available for the user to use. If you
      give it a command name as an argument, it will read you the extended
      "manpage" for that command.

    Usage
    -----
    !help
    !help <command>

    Examples
    --------
    """

    help_docs = []
    msg = Message(flask.request.form)

    # iterate through our routes, getting the doc-strings we defined as
    # miniature man-pages for these commands.
    hiddenEndpoints = set(['/', '/help'])
    for r in app.url_map.iter_rules():
        current_doc = app.view_functions[r.endpoint].__doc__
        if current_doc:
            if 'static'in r.rule:
                continue
            if r.rule in hiddenEndpoints:
                continue
            
            docString = current_doc.strip()
            firstLine = docString.split('\n', 1)[0]

            # if someone wants help about a specific command, get them
            # the extra info we placed after the first line-break.
            if msg.textBody:
                if firstLine.split(' ',1)[0].replace('!','') == msg.textBody.lower():
                    specificDocumentation = docString.split('\n',1)
                    if len(specificDocumentation) == 2:
                        return reduce_output(specificDocumentation[1].strip(),
                                             delimiter='\n')
                    else:
                        return 'No documentation for {0} yet. Add it to the\
                        repo! https://github.com/inculi/Sue'.format(msg.command)
                    
            help_docs.append(firstLine)

    return reduce_output(sorted(help_docs), delimiter='\n')