# -*- encoding: utf-8 -*-

require 'date'
require 'net/http'
require 'uri'
require 'json'
require_relative '../lib/vkontakte'

APP_ID = '1915108'

#print 'Email: '
#email = gets.chomp
email = 'anton.linux@gmail.com'

# Hide password
#print 'Password: '
#system "stty -echo"
#pass = $stdin.gets.chomp
#system "stty echo"
pass = ''

# Авторизація користувача за допомогою Desktop API
vk = VK::DesktopAuth.new(APP_ID)
vk.login!(email, pass)

mid, sid, secret = vk.mid, vk.sid, vk.secret

api = VK::API.new(APP_ID, mid, sid, secret)

# Отримання даних, необхідних для підключення до Long Poll сервера
# за допомогою методу messages.getLongPollServer:
# * key - секретний ключ сесії
# * server - адреса сервера до якого потрібно відправляти запит
# * ts - номер останньої події, починаючи з якої ви хочете отримати дані
#
resp = api.messages_getLongPollServer
key, server, ts = resp['key'], resp['server'], resp['ts']

while true do
  # Підключення до Long Poll сервера
  url = "http://#{server}?act=a_check&key=#{key}&ts=#{ts}&wait=25"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)

  begin
    res = http.request(Net::HTTP::Get.new(uri.request_uri))
  rescue => e
    puts "[ERROR] #{e}"
    sleep 5
    retry
  end

  begin
    params = JSON::parse(res.body)
  rescue JSON::ParserError
    puts '[ERROR] JSON Parse Error'
  end

  # Час дії ключа для підключення до LongPoll сервера може вичерпатись
  # через деякий час, сервер поверне параметр failed:
  # {failed: 2}
  # в такому випадку потрібно перепитати його
  # використовуючи метод messages.getLongPollServer
  #
  if params['failed'] == 2
    puts "[WARNING] Re-initilize Long Pool Server"
    resp = api.messages_getLongPollServer
    key, server, ts = resp['key'], resp['server'], resp['ts']
    next
  end

  if params['updates']
    params['updates'].each do |e|
      uid = e[1].abs
      user = api.getProfiles(:uids => uid, :fields => 'sex').first
      puts e if user.nil? # тут часом виникає помилка
      first_name = user['first_name']
      last_name = user['last_name']
      state = ['стало', 'стала', 'став'][user['sex'].to_i]
      case e[0]
      when 8 then
        puts "#{Time.now.strftime("%d/%m/%y %H:%M:%S")}: #{first_name} #{last_name} #{state} онлайн"
      when 9 then
        puts "#{Time.now.strftime("%d/%m/%y %H:%M:%S")}: #{first_name} #{last_name} #{state} оффлайн"
      end
    end
  end
  # Збереження нового значення ts, яке буде передаватися при наступному запиті
  ts = params['ts']
end
