# coding: utf-8

#=== nanacoギフトID一括登録スクリプト ===

require 'mechanize'

require './config.rb'

GIFT_ID_FILE = './id.txt'
LOG_FILE = './log.txt'

CARD_NO = Config::CARD_NO.to_s
CARD_PASSWORD = Config::PASSWORD.to_s


module Output
  def self.console_and_file(output_file)
    defout = Object.new
    defout.instance_eval { @ofile = open(output_file, 'a') }
    class << defout
      def write(str)
        STDOUT.write(str)
        @ofile.write(str)
      end
    end
    $stdout = defout
  end
end

Output.console_and_file(LOG_FILE)


def load_gift_id()
  gift_id_file = ""
  gift_id_list = []

  File.open(GIFT_ID_FILE, 'r') { |file|
    gift_id_file = file.read
  }

  gift_id_file.each_line { |line|
    if line.scan(/[a-zA-Z\d]/).size == 16
      gift_id_list.push(line.scan(/[a-zA-Z\d]{4}/))
    else
      puts "不正なギフトID: #{line.strip}"
      next
    end
  }

  return gift_id_list
end

def check_error(target, page, gift_id = nil)
  error_msg = nil

  case target

  # ログインエラー
  when :login
    error_elem = page.search('.err')
    unless error_elem.empty?
      return error_elem.text.gsub(/\s/, '')
    end

  # ギフトIDエラー（他カードで登録済み）
  when :id_error
    error_elem = page.search('#error')
    unless error_elem.empty?
      error_msg = error_elem.text.gsub(/\s/, '')
    end

  # ギフトID登録済み
  when :id_used
    error_elem = page.search('#error500')
    unless error_elem.empty?
      error_msg = error_elem.text.strip
    end
  end

  if error_msg
    @error_count += 1
    puts "[#{@count}/#{@total_count}] #{gift_id.join('-')}: #{error_msg}"
  end
  return error_msg
end

def check_balance(page)
  values = page.search('#memberInfoFull .fRight')
  balance = {
    card_balance:   values[0].text.strip,
    card_point:     values[1].text.strip,
    center_balance: values[2].text.strip,
    center_point:   values[3].text.strip,
  }
end

def check_result(page)
  result = {
    gift_id:    page.search('#registerForm td')[1].text,
    amount:     page.search('#registerForm td')[2].text,
    receipt_no: page.search('#registerForm td')[3].text,
    valid_from: page.search('#registerForm td')[4].text,
  }
end

def wait(sec = 1)
  sleep sec
end


@count = 0
@total_count = 0
@success_count = 0
@error_count = 0


puts "=== nanacoギフトID一括登録 (#{Time.now}) ==="

puts "登録先nanaco番号: #{CARD_NO.scan(/\d{4}/).join('-')}"

gift_id_list = load_gift_id()
@total_count = gift_id_list.count

if @total_count < 1
  puts "利用可能なギフトIDがありません"
  exit(1)
else
  puts "#{@total_count} 件のギフトIDを登録します"
end

# ログイン
agent = Mechanize.new
agent.max_history = 2

page = agent.get('https://www.nanaco-net.jp/pc/emServlet?gid=')
wait()

form = page.form_with(name: 'formLoginPass')
form.XCID = CARD_NO
form.LOGIN_PWD = CARD_PASSWORD
button = form.button_with(name: 'ACT_ACBS_do_LOGIN1')

member_page = agent.submit(form, button)
wait()
error = check_error(:login, member_page)
if error
  puts "ログインエラー: #{error}"
  exit(1)
else
  puts "ログインしました"
end

# 残高確認
balance = check_balance(member_page)
puts "残高 (ポイント) => [カード] #{balance[:card_balance]} (#{balance[:card_point]}) / [センター] #{balance[:center_balance]} (#{balance[:center_point]})"

# ギフトID登録
gift_id_page = member_page.link_with(text: "nanacoギフト登録").click

gift_id_list.each_with_index { |id, i|
  @count = i + 1

  form = gift_id_page.form_with(action: 'https://nanacogift.jp/ap/p/top.do')
  page = agent.submit(form)
  wait()

  # ギフトID入力
  form = page.form_with(name: 'EjoicaActionForm')
  form.id1 = id[0]
  form.id2 = id[1]
  form.id3 = id[2]
  form.id4 = id[3]

  # ギフトID登録確認
  page = agent.submit(form)
  wait()
  next if check_error(:id_error, page, id)
  next if check_error(:id_used, page, id)

  # ギフトID登録完了
  form = page.form_with(action: '/ap/p/register4.do')
  page = agent.submit(form)
  wait()
  next if check_error(:id_used, page, id)

  result = check_result(page)
  @success_count += 1
  puts "[#{@count}/#{@total_count}] #{result[:gift_id]}: #{result[:amount]} 受取可能日時: #{result[:valid_from]}"
}

# ログアウト
page = member_page.link_with(text: "ログアウト").click
puts page.search('#textFin').text

puts "[登録成功] #{@success_count} 件 / [登録失敗] #{@error_count} 件"
