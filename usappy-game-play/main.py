# coding: utf-8

import config
import datetime
import re
import requests
import time
from bs4 import BeautifulSoup
from logger import logger


LOGIN_URL = 'https://usappy.jp/login'
LOGOUT_URL = 'https://usappy.jp/logout'
GAME_URL_LIST = [
    'https://usappy.jp/game/race/',
    'https://usappy.jp/game/lot/',
    'https://usappy.jp/game/scratch/',
    'https://usappy.jp/game/bowling/'
]
START_ACT = 'start?'
RESULT_ACT = 'result'

LOGIN_DATA = {
    '_email': config.EMAIL,
    '_password': config.PASS
}
SCRIPT_NAME = config.SCRIPT_NAME


def sleep():
    time.sleep(1)


# Endpoint of Google Cloud Functions -> main()
def main(event={}, context={}):
    today = datetime.datetime.now().strftime('%Y-%m-%d')
    point_sum = 0

    try:
        ses = requests.session()
        res = ses.get(LOGIN_URL)
        cookie = res.cookies
        ses.post(LOGIN_URL, data=LOGIN_DATA, cookies=cookie)
        sleep()

        for url in GAME_URL_LIST:
            ses.get(url + START_ACT, cookies=cookie)
            sleep()
            game_res = ses.get(url + RESULT_ACT, cookies=cookie)
            sleep()

            bs = BeautifulSoup(game_res.text, 'html.parser')
            result_text = bs.find("div", class_="mini_game").p.string
            point = re.search(r'\d+', result_text)
            if point is not None:
                point_sum += int(point.group())

        ses.get(LOGOUT_URL, cookies=cookie)

    except requests.exceptions.RequestException as e:
        logger.error(f"[{SCRIPT_NAME}] {e}")
    else:
        logger.info(f"[{SCRIPT_NAME}] {today}: {str(point_sum)} P Get")


if __name__ == '__main__':
    main()
