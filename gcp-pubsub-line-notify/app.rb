# coding: utf-8

require "base64"
require "functions_framework"
require "google/cloud/secret_manager"
require "json"
require "net/http"
require "time"
require "uri"

class Line
  URI = URI.parse('https://api.line.me/v2/bot/message/broadcast')

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

  def make_broadcast_request(data)
    secrets = get_secrets()
    token = secrets['channel_access_token']
    req = Net::HTTP::Post.new(URI.path)
    req["Content-Type"] = "application/json"
    req["Authorization"] = "Bearer #{token}"
    req.body = data.to_json
    return req
  end

  def send_broadcast(msg)
    data = {
      "messages" => [
        {
          "type" => "text",
          "text" => msg
        }
      ]
    }
    http = Net::HTTP.new(URI.host, URI.port)
    req = make_broadcast_request(data)
    res = Net::HTTP.start(URI.hostname, URI.port, use_ssl: URI.scheme == "https") do |https|
      https.request(req)
    end
  end
end

# Cloud Functions entry point -> function
FunctionsFramework.cloud_event 'function' do |event|
  event_msg_json = Base64.decode64(event.data["message"]["data"])
  event_msg = JSON.parse(event_msg_json)

  event_text = event_msg["textPayload"]

  event_time = event_msg["timestamp"]
  utc_time = Time.parse(event_time)
  jst_time = utc_time.getlocal('+09:00')

  line_msg = "#{event_text}\n#{jst_time.strftime('%Y-%m-%d %H:%M:%S')}"

  line = Line.new
  line.send_broadcast(line_msg.force_encoding("UTF-8"))
end
