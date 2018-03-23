import requests

url = 'http://127.0.0.1:5000/'

payload = {
    'buddyId': 'B4C24F07-9A5C-4816-92BD-464AAE7C1A0A:+12107485865',
    'chatId' : 'singleUser',
    'textBody' : "",
    'fileName' : 'noFile'
}

r = requests.get(url, data=payload)
print(r.content)