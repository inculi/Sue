import flask
import logging
import uuid

from sue.extensions import assets
from sue.logic import register_logic

def create_app(config):
    """ Sue app factory. """
    app = flask.Flask(__name__)
    app.config.from_object(config)

    # Debugging
    if app.config['DEBUG']:
        app.logger.setLevel(logging.DEBUG)
    else:
        app.logger.setLevel(logging.WARNING)

    # Logging
    if 'LOG_FILE' in app.config:
        from logging.handlers import RotatingFileHandler
        app.log_handler = RotatingFileHandler(
            app.config['LOG_FILE'], maxBytes=10000, backupCount=1)
        app.logger.addHandler(app.log_handler)

    if not app.config['DEBUG']:
        @app.errorhandler(500)
        def internal_error(exception):
            random_id = uuid.uuid4()
            app.logger.error('Exception occurred. ID: %s' % random_id,
                             exc_info=exception)

    # Database
    # configure database here once it's up and running
    assets.init_app(app)
    register_logic(app)

    return app
