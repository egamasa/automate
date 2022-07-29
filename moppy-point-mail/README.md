# moppyPointMail

Earn points from moppy point mail automatically.

## Settings

- **config.py**
  - `SCRIPT_NAME`  
    Name label written in logs.
  - `IMAP_HOST`  
    IMAP mail server host
  - `IMAP_PORT`  
    IMAP mail server port
  - `IMAP_SSL`  
    Use IMAP mail server through SSL
    - true / false
- **env.yaml**
  - `PROJECT_ID`  
    GCP project ID that place this function.
  - `SECRET_NAME`  
    Secret name of GCP Secret Manager that saved secrets of IMAP mail server and moppy account.
- **secrets.json**
  - `imap_user`  
    IMAP username
  - `imap_pass`  
    IMAP password
  - `moppy_user`  
    moppy username
  - `moppy_pass`  
    moppy password

## Deploy to Google Cloud Functions

### Add secret to GCP Secret Manager

```
$ gcloud secrets create moppy-point-mail-secrets \
    --data-file=secrets.json \
    --locations=asia-northeast1 \
    --replication-policy=user-managed
```

### Create a Cloud Pub/Sub topic.

```
$ gcloud pubsub topics create moppy-point-mail-topic
```

### Deploy as a Google Cloud Function.

```
$ gcloud functions deploy moppy-point-mail \
    --entry-point=moppy \
    --memory=128MB \
    --timeout=120 \
    --runtime=ruby27 \
    --region=asia-northeast1 \
    --trigger-topic=moppy-point-mail-topic \
    --env-vars-file=env.yaml
```

### Create a Cloud Scheduler job with a Pub/Sub target.

```
$ gcloud beta scheduler jobs create pubsub moppy-point-mail-job \
    --schedule="50 23 * * *" \
    --topic=moppy-point-mail-topic \
    --message-body="{}" \
    --time-zone=Asia/Tokyo
```

- `--schedule`  
  Write in Linux crontab format.
