# coding: utf-8

require "functions_framework"
require "google/cloud/secret_manager"
require "json"
require "twitter"

# ツイート取得上限3200件（200件/回*16回）
MAX_TIMES = 3200 / 200

def get_secrets()
  project_id = ENV['PROJECT_ID']
  secret_name = ENV['SECRET_NAME']

  client = Google::Cloud::SecretManager.secret_manager_service
  key = client.secret_version_path(
    project: project_id,
    secret: secret_name,
    secret_version: 'latest'
  )
  res = client.access_secret_version(
    name: key
  )
  return JSON.parse(res.payload.data)
end

# Cloud Functions entry point -> main
FunctionsFramework.cloud_event "main" do |event|

  secrets = get_secrets

  # For Twitter API v1.1
  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = secrets["consumer_key"]
    config.consumer_secret     = secrets["consumer_secret"]
    config.access_token        = secrets["access_token"]
    config.access_token_secret = secrets["access_token_secret"]
  end

  t = Time.now
  today = Time.new(t.year, t.month, t.day, 0, 0, 0, "+09:00")
  yesterday = today - 60*60*24

  user = client.user
  options = {count: 200, include_rts: true}

  user_name = user.name
  screen_name = user.screen_name
  total_tweets_count = user.tweets_count

  all_tweets = []

  MAX_TIMES.times do
    tweets = client.user_timeline(user, options)
    all_tweets.concat(tweets)

    break if tweets.last.created_at < yesterday

    all_tweets.delete_at(-1)
    options[:max_id] = tweets.last.id
  end

  count = 0
  retweet_count = 0
  hashtags = {}

  all_tweets.each do |tweet|
    next unless yesterday < tweet.created_at && tweet.created_at < today

    count += 1
    retweet_count += 1 if tweet.retweeted_tweet?

    # ハッシュタグ集計
    tweet.hashtags.each do |tag|
      if hashtags.key?(tag.text)
        hashtags[tag.text] += 1
      else
        hashtags.store(tag.text, 1)
      end
    end
  end

  hot_hashtags = hashtags.sort{ |a, b| b[1] <=> a[1] }
  hot_hashtags_text = hot_hashtags[0..9].map{ |tag| tag[0] }.join(', ')

  tweet_text =
  "#{user_name} @#{screen_name}\n\
  #{yesterday.strftime("%Y/%m/%d (%a.)")} のツイート数：#{count}（RT：#{retweet_count}）\n\
  総ツイート数：#{total_tweets_count}\n\
  #🔥 #{hot_hashtags_text}"

  client.update(tweet_text)

end
