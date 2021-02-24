# UsappyGamePlay

Play mini games of [Usappy.jp](https://usappy.jp) automatically.


## Settings

- **config.py**
  - `SCRIPT_NAME`  
    Name label written in logs.
  - `USE_ENV_VARIABLE`  
    Load Usappy account from environment variables.
    - True / False
- **env.yaml**  
  Apply login data of Usappy account when use environment variables.
  - `EMAIL`  
    E-mail address of Usappy account
  - `PASS`  
    Password of Usappy account


## Deploy to Google Cloud Functions

### Create a Cloud Pub/Sub topic.

```
$ gcloud pubsub topics create usappy-game-topic
```

### Deploy as a Google Cloud Function.

```
$ gcloud functions deploy usappy-game \
    --entry-point=main \
    --memory=128MB \
    --timeout=60 \
    --runtime=python38 \
    --region=asia-northeast1 \
    --trigger-topic=usappy-game-topic \
    --env-vars-file=env.yaml
```

### Create a Cloud Scheduler job with a Pub/Sub target.

```
$ gcloud beta scheduler jobs create pubsub usappy-game-job \
    --schedule="0 11 * * *" \
    --topic=usappy-game-topic \
    --message-body="{}" \
    --time-zone=Asia/Tokyo
```

- `--schedule`  
  Write in Linux crontab format.
