import requests
from telegram.ext import Updater, CommandHandler
from telegram import MessageEntity, Message
import json
from pprint import pprint


class SueTelegram(object):
    def __init__(self, token):
        self.updater = updater = Updater(token, use_context=True)
        self.init_handlers()
        self.run()

    def init_handlers(self):
        """
        Contact Sue, asking for her list of available commands.
        """
        r = requests.get("http://localhost:5000/api/functree")
        pprint(r.content)
        for commandName in json.loads(r.content):
            self.updater.dispatcher.add_handler(
                CommandHandler(commandName, self.handler)
            )

    def run(self):
        self.updater.start_polling()
        self.updater.idle()
    
    def handler(self, update, context):
        cmd = self.get_command(update)
        pprint(update.message.chat.__dict__)
        pprint(update.message.from_user.__dict__)
        payload = {
            'chatId' : 'debug',
            'textBody' : '!' + update.message.text[1:],
            'buddyId' : '',
            'fileName' : ''
        }
        r = requests.get('http://localhost:5000/', data=payload)
        update.message.reply_text(r.content.decode('utf8'))

    @staticmethod
    def get_command(update):
        """
        Given an update, find its first associated bot command, minus the slash.
        Ex: /random 1 10 -> 'random'
        """
        for e in update.message.entities:
            if e.type == MessageEntity.BOT_COMMAND:
                return update.message.text[e.offset:e.offset+e.length][1:]
        return ''

if __name__ == "__main__":
    TOKEN = "680483433:AAHQUqWifMpR3qEMdFqyXqW3L3g-pe11638"
    st = SueTelegram(TOKEN)
    st.run()
