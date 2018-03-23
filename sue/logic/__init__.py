# in each of these files is where we will store the logic to our specific
from sue.logic import (
    main,
    rand,
    userdefs,
    webapis,
    cmds,
    images,
    poll
)

def register_logic(flask_app):
    """ Attach the blueprints we have made to our flask application. """
    flask_app.register_blueprint(main.bp)
    flask_app.register_blueprint(rand.bp)
    flask_app.register_blueprint(userdefs.bp)
    flask_app.register_blueprint(webapis.bp)
    flask_app.register_blueprint(cmds.bp)
    flask_app.register_blueprint(images.bp)
    flask_app.register_blueprint(poll.bp)

    return flask_app