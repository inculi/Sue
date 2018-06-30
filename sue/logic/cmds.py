import flask
from pprint import pprint

app = flask.current_app
bp = flask.Blueprint('cmds', __name__)

def do_command(cmdString):
    """Utility function to execute command in bash and return output as a
    unicode string.
    """
    import subprocess
    output = subprocess.check_output(cmdString, shell=True)
    return output.decode('utf-8')

@bp.route('/fortune')
def fortune():
    """!fortune

    Tell a random, hopefully interesting adage.
    Usage: !fortune
    """

    return do_command("/usr/local/bin/fortune")

@bp.route('/dirty')
def dirty():
    """!dirty

    Like fortune, but the output is selected from potentially offensive
    aphorisms
    Usage: !dirty
    """
    return do_command("/usr/local/bin/fortune -o")

@bp.route('/uptime')
def uptime():
    """!uptime

    Show how long Sue's server has been running.
    Usage: !uptime
    """
    return do_command("uptime")

@bp.route('/rancher', methods=['GET', 'POST'])
def rancher():
    import json
    from sue.models import DirectResponse

    a = json.loads(flask.request.data.decode('utf-8'))
    b = "Alert from Rancher:\n%s" % json.dumps(a, indent=2)

    DirectResponse('robert', b)
    # DirectResponse('james', b)

    return ''
