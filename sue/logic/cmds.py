import flask

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
    """

    return do_command("/usr/local/bin/fortune")

@bp.route('/dirty')
def dirty():
    """!dirty

    Like fortune, but the output is selected from potentially offensive
    aphorisms
    """
    return do_command("/usr/local/bin/fortune -o")

@bp.route('/uptime')
def uptime():
    """!uptime
    
    Show how long Sue's server has been running.
    """
    return do_command("uptime")