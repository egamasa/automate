# coding: utf-8

#=== moppyポイント付メール自動取得スクリプト ===

require "functions_framework"
require "google/cloud/secret_manager"
require "json"
require 'mail'
require 'mechanize'
require 'net/imap'
require 'uri'

require './config.rb'


SCRIPT_NAME = Config::SCRIPT_NAME
IMAP_HOST = Config::IMAP_HOST
IMAP_PORT = Config::IMAP_PORT
IMAP_SSL = Config::IMAP_SSL


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

def log(severity, message)
  msg = {
    "severity": severity,
    "message": message
  }
  print msg.to_json
end

def wait(sec = 2)
  sleep sec
end


FunctionsFramework.cloud_event "moppy" do |event|
  secrets = get_secrets()

  # メール取得・URL抽出
  imap = Net::IMAP.new(IMAP_HOST, IMAP_PORT, IMAP_SSL)

  imap_user = secrets['imap_user']
  imap_passwd = secrets['imap_pass']
  imap.login(imap_user, imap_passwd)
  wait()

  imap.select('INBOX')
  wait()

  queue_urls = []

  query = [
    "SUBJECT", "コイン付".force_encoding('ASCII-8BIT'),
    "ON", Net::IMAP.format_date(Time.new)
  ]
  msg_ids = imap.search(query)
  wait()

  imap.fetch(msg_ids, "RFC822").each do |msg|
    mail = Mail.new(msg.attr["RFC822"])
    urls = URI.extract(mail.decoded, ["https"])
    urls.delete_if {|s| !s.include?("https://pc.moppy.jp/clc/?clc_tag")}
    urls.uniq!
    queue_urls.concat(urls)
  end
  wait()

  imap.logout
  wait()
  imap.disconnect
  wait()

  # moppyログイン
  agent = Mechanize.new
  agent.max_history = 2
  agent.user_agent_alias = 'Windows Mozilla'

  page = agent.get('https://ssl.pc.moppy.jp/login/')
  wait()

  form = page.form_with(action: '/login/?mode=submit')
  form.mail = secrets['moppy_user']
  form.pass = secrets['moppy_pass']
  button = form.button_with(class: 'a-btn__login')

  page = agent.submit(form, button)
  wait()

  # メール抽出URLアクセス
  queue_urls.each do |url|
    page = agent.get(url)
    wait()
  end

  # ガチャ実行
  page = agent.get('https://pc.moppy.jp/pc_gacha/')
  wait()
  page = agent.get('https://pc.moppy.jp/pc_gacha/result.php')
  wait()
  gacha_ad_page = agent.get('https://pc.moppy.jp/pc_gacha/ad_click.php')
  wait()

  # ポイント・コイン数取得
  page = agent.get('https://pc.moppy.jp/mypage/')
  wait()

  points = page.search('.a-point__point')[0].text.strip
  exp_points = page.search('.a-point__other dd')[0].text.strip
  coins = page.search('.a-point__other dd')[1].text.strip

  points_text = "[#{SCRIPT_NAME}] #{points} (#{exp_points}) / #{coins}"
  log("INFO", points_text)
end
