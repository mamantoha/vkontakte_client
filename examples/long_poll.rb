# -*- encoding: utf-8 -*-

require 'bundler'
Bundler.setup :default

require 'vkontakte'

require 'date'
require 'net/http'
require 'uri'
require 'json'

CLIENT_SECRET = 'BsCEIfRxoDFZU8vZJ65v'
CLIENT_ID     = '1915108'

offline = "\033[31;3mофлайн\033[0m"
online = "\033[32;3mонлайн\033[0m"

vk = Vkontakte::Client.new(CLIENT_ID, CLIENT_SECRET)

#print 'Email: '
#email = gets.chomp
email = 'anton.linux@gmail.com'

# Hide password
print 'Password: '
system "stty -echo"
pass = $stdin.gets.chomp
system "stty echo"
#pass = ''

vk.login!(email, pass, 'messages')

# Отримання даних, необхідних для підключення до Long Poll сервера
# за допомогою методу messages.getLongPollServer:
# * key - секретний ключ сесії
# * server - адреса сервера до якого потрібно відправляти запит
# * ts - номер останньої події, починаючи з якої ви хочете отримати дані
#
resp = vk.api.messages_getLongPollServer
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
    puts "[INFO] Re-initilize Long Pool Server"

    begin
      resp = vk.api.messages_getLongPollServer
      key, server, ts = resp['key'], resp['server'], resp['ts']
    rescue Vkontakte::VkException => ex
      if ex.error_code == 5
        puts "[ERROR] User authorization failed: access_token have heen expired"
        puts "[INFO] Getting a new access_token"
        vk.login!(email, pass, 'messages')
        retry
      end
    end

    next
  end

  if params['updates']
    params['updates'].each do |e|
      uid = e[1].abs
      # `method_missing': Error in `getProfiles': 5: User authorization failed: access_token have heen expired.
      begin
        user = vk.api.getProfiles(:uids => uid, :fields => 'sex').first
      rescue Vkontakte::VkException => ex
        if ex.error_code == 5
          puts "[ERROR] #{ex.error_msg}"
          puts "[INFO] Getting a new access_token"
          vk.login!(email, pass, 'messages')
          retry
        end
      end
      puts e if user.nil? # тут часом виникає помилка
      first_name = user['first_name']
      last_name = user['last_name']
      state = ['стало', 'стала', 'став'][user['sex'].to_i]
      case e[0]
      when 8 then
        puts "#{Time.now.strftime("%d/%m/%y %H:%M:%S")}: #{first_name} #{last_name} #{state} #{online}"
      when 9 then
        puts "#{Time.now.strftime("%d/%m/%y %H:%M:%S")}: #{first_name} #{last_name} #{state} #{offline}"
      end
    end
  end
  # Збереження нового значення ts, яке буде передаватися при наступному запиті
  ts = params['ts']
end
