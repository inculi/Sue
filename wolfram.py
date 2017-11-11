import wolframalpha
from pprint import pprint
client = wolframalpha.Client('HWP8QY-EL2KR2KKLW')

def wolframQuery(inputQuestion):
    res = client.query(inputQuestion)

    interp = [pod for pod in res.pods if pod['@title'] == 'Input interpretation']
    results = [pod for pod in res.pods if pod['@title'] == 'Result']

    print('Input:')
    for item in interp:
        try:
            print(item['subpod']['img']['@alt'])
        except:
            pass # didn't have the right keys.

    print('\nResult:')
    for res in results:
        try:
            print(res['subpod']['img']['@alt'])
        except:
            pass # didn't have the right keys.

wolframQuery('(volume of the sun)/(volume of a dolphin)')