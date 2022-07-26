import config
import datetime
import json
import re
import requests
import time
from bs4 import BeautifulSoup


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

HEADER = {
    'User-Agent': ('Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                   'AppleWebKit/537.36 (KHTML, like Gecko) '
                   'Chrome/103.0.0.0 Safari/537.36')
}


def log(severity, message):
    print(json.dumps(dict(severity=severity, message=message)))


def sleep():
    time.sleep(1)


# Endpoint of Google Cloud Functions -> main()
def main(event={}, context={}):
    today = datetime.datetime.now().strftime('%Y-%m-%d')
    point_sum = 0

    try:
        ses = requests.session()
        res = ses.get(LOGIN_URL, headers=HEADER)
        cookie = res.cookies
        ses.post(LOGIN_URL, data=LOGIN_DATA, cookies=cookie, headers=HEADER)
        sleep()

        for url in GAME_URL_LIST:
            ses.get(url + START_ACT, cookies=cookie, headers=HEADER)
            sleep()
            game_res = ses.get(
                url + RESULT_ACT, cookies=cookie, headers=HEADER)
            sleep()

            bs = BeautifulSoup(game_res.text, 'html.parser')
            result_text = bs.find("div", class_="mini_game").p.text
            point = re.search(r'\d+', result_text)
            if point is not None:
                point_sum += int(point.group())

        ses.get(LOGOUT_URL, cookies=cookie)

    except requests.exceptions.RequestException as e:
        log("ERROR", f"[{SCRIPT_NAME}] {e}")
    else:
        log("INFO", f"[{SCRIPT_NAME}] {today}: {str(point_sum)} P Get")


if __name__ == '__main__':
    main()
