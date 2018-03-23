import flask

from sue.models import Message
from sue.utils import reduce_output

app = flask.current_app
bp = flask.Blueprint('images', __name__)

@bp.route('/identify')
def identify():
    """!identify <image>"""
    
    msg = Message._create_message(flask.request.form)
    fileName = msg.fileName

    if fileName == 'noFile':
        return 'Please supply a file.'
    elif fileName == 'fileError':
        return 'There was an error selecting the last file transfer.'
    else:
        from clarifai.rest import ClarifaiApp
        from clarifai.rest import Image as ClImage

        app = ClarifaiApp(api_key='ab4ea7efce5a4398bcbed8329a3d81c7')
        model = app.models.get('general-v1.3')
        image = ClImage(file_obj=open(fileName, 'rb'))

        imageData = model.predict([image])
        try:
            imageData = imageData['outputs'][0]['data']['concepts'][:10]
            imageData = [x['name'] for x in imageData]

            return reduce_output(imageData, delimiter=', ')
        except:
            return 'Error'

@bp.route('/person')
def person():
    """!person <image>"""
    msg = Message._create_message(flask.request.form)
    fileName = msg.fileName

    if fileName == 'noFile':
        return 'Please supply a file.'
    elif fileName == 'fileError':
        return 'There was an error selecting the last file transfer.'
    else:
        from clarifai.rest import ClarifaiApp
        from clarifai.rest import Image as ClImage

        responses = []

        app = ClarifaiApp(api_key='ab4ea7efce5a4398bcbed8329a3d81c7')
        model = app.models.get('demographics')
        image = ClImage(file_obj=open(fileName, 'rb'))

        imageData = model.predict([image])
        imageData = imageData['outputs'][0]['data']
        if 'regions' not in imageData:
            return 'No faces detected.'
        for face in imageData['regions']:
            face = face['data']['face']
            try:
                face_age = face['age_appearance']['concepts'][0]['name']
                face_gender = face['gender_appearance']['concepts'][0]['name']
                face_culture = face['multicultural_appearance']['concepts'][0]['name']
                responses.append('age : %s' % face_age)
                responses.append('gender : %s' % face_gender)
                responses.append('ethnicity : %s' % face_culture)
            except:
                return 'Error'
    
    return responses

@bp.route('/lewd')
def lewd():
    """!lewd <image>"""
    # detect whether an image is lewd or not

    msg = Message._create_message(flask.request.form)
    fileName = msg.fileName

    if fileName == 'noFile':
        return 'Please supply a file.'
    elif fileName == 'fileError':
        return 'There was an error selecting the last file transfer.'
    else:
        from clarifai.rest import ClarifaiApp
        from clarifai.rest import Image as ClImage

        app = ClarifaiApp(api_key='ab4ea7efce5a4398bcbed8329a3d81c7')
        model = app.models.get('nsfw-v1.0')
        image = ClImage(file_obj=open(fileName, 'rb'))

        responses = []

        imageData = model.predict([image])
        result = imageData['outputs'][0]['data']['concepts'][0]
        if result['name'] == u'nsfw':
            responses.append('LEEEWWWDDD!!!!!')
            responses.append('accuracy: %f' % result['value'])

            return responses
        else:
            return 'not lewd'