import flask

app = flask.current_app
bp = flask.Blueprint('cmds', __name__)

@bp.route('/fortune')
def fortune():
    """!fortune"""
    import subprocess
    output = subprocess.check_output("/usr/local/bin/fortune", shell=True)
    return output

@bp.route('/dirty')
def dirty():
    """!dirty"""
    import subprocess
    output = subprocess.check_output("/usr/local/bin/fortune -o", shell=True)
    return output

@bp.route('/uptime')
def uptime():
    """!uptime"""
    import subprocess
    output = subprocess.check_output("uptime", shell=True)
    return output