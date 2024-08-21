# 実行例（ローカル環境）
# $ python3 radiko_download.py FMT 202408181700 202408181755 'NISSAN あ、安部礼司 ～BEYOND THE AVERAGE～'

from Radiko import RadikoClient
import subprocess
from subprocess import PIPE
import sys

def lambda_hundler(event, context):
    client = RadikoClient()

    # 放送局利用可否判定
    station_id = event['station_id']
    if client.is_available_station_id(station_id):
        print(f"Station ID: {station_id} is available.")
    else:
        print(f"Station ID: {station_id} is not available!")
        sys.exit()

    # トークン取得
    auth_token = client.get_auth_token_4_station_id(station_id)
    if auth_token == 'prohibited':
        print('Authentication error!')
        sys.exit()

    # ストリームURL取得
    stream_urls = client.get_stream_base_urls(station_id, timefree=True, areafree=False)

    ft = event['ft'] + '00'
    to = event['to'] + '00'
    time_shift_stream_url = stream_urls[-1] + f"?station_id={station_id}&l=15&ft={ft}&to={to}"

    title = event['title']
    file_name = f"{station_id}_{title}_{event['ft']}"

    ffmpeg_cmd = f'ffmpeg -headers "X-RADIKO-AUTHTOKEN: {auth_token}" -i "{time_shift_stream_url}" -acodec copy "{file_name}.aac"'
    print(ffmpeg_cmd)

    # ダウンロード（要 ffmpeg）
    proc = subprocess.run(ffmpeg_cmd, shell=True, stdout=PIPE, stderr=PIPE, text=True)
    if proc.returncode == 0:
        print("Download completed.")
    else:
        print("Download failed!")


if __name__ == "__main__":
    args = sys.argv

    payload = {
        "station_id": args[1],
        "ft": args[2],
        "to": args[3],
        "title": args[4]
    }

    lambda_hundler(payload, '')
