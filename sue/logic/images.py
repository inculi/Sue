import os
import random

import flask

from sue.models import Message, DataResponse
from sue.utils import reduce_output

app = flask.current_app
bp = flask.Blueprint('images', __name__)

VALID_IMAGE_PARAMS = set([
    'smile', 'smile_2', 'hot', 'old', 'young', 'hollywood', 'glasses',
    'hitman', 'mustache', 'pan', 'heisenberg', 'female', 'female_2',
    'male'])

@bp.route('/identify')
def identify():
    """!identify <image>
    
    Queries clarif.ai to identify the top 10 concepts within an image.
    Usage: !identify <image>"""
    
    msg = Message(flask.request.form)
    fileName = msg.fileName

    if fileName == 'noFile':
        return 'Please supply a file.'
    elif fileName == 'fileError':
        return 'There was an error selecting the last file transfer.'
    else:
        from clarifai.rest import ClarifaiApp
        from clarifai.rest import Image as ClImage

        capp = ClarifaiApp(api_key=app.config['CLARIFAI_KEY'])
        model = capp.models.get('general-v1.3')
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
    """!person <image>
    
    Queries clarif.ai to identify the age, gender, and 'multicultural apperance'\
    of detected faces in the photo.
    Usage: !person <image>"""
    msg = Message(flask.request.form)
    fileName = msg.fileName

    if fileName == 'noFile':
        return 'Please supply a file.'
    elif fileName == 'fileError':
        return 'There was an error selecting the last file transfer.'
    else:
        from clarifai.rest import ClarifaiApp
        from clarifai.rest import Image as ClImage

        responses = []

        app = ClarifaiApp(api_key=app.config['CLARIFAI_KEY'])
        model = app.models.get('demographics')
        image = ClImage(file_obj=open(fileName, 'rb'))

        imageData = model.predict([image])
        imageData = imageData['outputs'][0]['data']
        if 'regions' not in imageData:
            return 'No faces detected.'
        for face in imageData['regions']:
            face = face.get('data',{}).get('face')
            try:
                if face:
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
    """!lewd <image>
    
    Queries clarif.ai to detect if an image is 'lewd'.
    Usage: !lewd <image>"""

    msg = Message(flask.request.form)
    fileName = msg.fileName

    if fileName == 'noFile':
        return 'Please supply a file.'
    elif fileName == 'fileError':
        return 'There was an error selecting the last file transfer.'
    else:
        from clarifai.rest import ClarifaiApp
        from clarifai.rest import Image as ClImage

        app = ClarifaiApp(api_key=app.config['CLARIFAI_KEY'])
        model = app.models.get('nsfw-v1.0')

        if not model:
            return 'Model no longer exists.'
        
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

def send_random_image(directory):
    if not directory.endswith('/'):
        directory = directory + '/'
    files = [f for f in os.listdir(directory) if f[0] != '.']
    return DataResponse(os.path.abspath(directory + random.choice(files)))


@bp.route('/qt')
def qt():
    """!qt

    Sends a cute image.
    """
    return send_random_image('resources/qt/')


@bp.route('/cringe')
def cringe():
    """!cringe

    Sends a cringe compilation image.
    """
    return send_random_image('resources/cringe/')


@bp.route('/i')
def image():
    """!i <param> <image>
    
    Available parameters are: smile, smile2, hot, old, young, hollywood, glasses, hitman, mustache, pan, heisenberg, female, female2, male
    """
    global VALID_IMAGE_PARAMS
    
    msg = Message(flask.request.form)
    _param = msg.textBody.lower()

    paramAliases = {
        'mustache' : 'mustache_free',
        'glasses' : 'fun_glasses',
        'smile2' : 'smile_2',
        'female2' : 'female_2'
    }

    if _param not in VALID_IMAGE_PARAMS:
        _param = paramAliases.get(_param)
        if not _param:
            return 'Not a valid parameter. See !help i'
    
    if msg.fileName == 'noFile':
        return 'Please supply a file.'
    elif msg.fileName == 'fileError':
        return 'There was an error selecting the last file transfer.'

    import faces
    import uuid

    try:
        img = faces.FaceAppImage(file=open(msg.fileName, 'rb'))
        outimg = img.apply_filter(_param, cropped=False)
    except faces.ImageHasNoFaces:
        return 'No faces on this image.'
    except faces.BadInfo as ex:
        return str(ex)

    # Create the directory for us to store these files if it doesn't exist.
    if not os.path.exists('resources/iout/'):
        os.mkdir('resources/iout')
    
    outPath = os.path.abspath('resources/iout/{}.jpg'.format(uuid.uuid4()))
    with open(outPath, 'wb') as f:
        f.write(outimg)
    
    return DataResponse(outPath)