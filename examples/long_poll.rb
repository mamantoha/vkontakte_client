# encoding: utf-8

require 'bundler'
Bundler.setup :default

require 'vkontakte'

require 'date'
require 'net/http'
require 'uri'
require 'json'

CLIENT_ID = '1915108'

offline = "\033[31;3mофлайн\033[0m"
online = "\033[32;3mонлайн\033[0m"

vk = Vkontakte::Client.new(CLIENT_ID)

credentials = Vkontakte::AskForCredentials.new
email = credentials.email
pass  = credentials.password

vk.login!(email, pass, permissions: 'messages')

# Следующие данные , необходимые для подключения к Long Poll серверу
# с помощью метода messages.getLongPollServer:
# * key - секретный ключ сессии
# * server - адреса сервера к которому нужно отправлять запрос
# * ts - номер последнего события, начиная с которого Вы хотите получать данные
# * mode - параметр, определяющий наличие поля прикрепления в получаемых данных. Значения: 2 - получать прикрепления, 0 - не получать.
#
# Для подключения Вам нужно составить запрос следующего вида:
# http://{$server}?act=a_check&key={$key}&ts={$ts}&wait=25&mode=2
#
resp = vk.api.messages_getLongPollServer
puts resp
key, server, ts = resp['key'], resp['server'], resp['ts']

while true do
  url = "http://#{server}?act=a_check&key=#{key}&ts=#{ts}&wait=25&mode=2"
  puts url
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

  # Время действия ключа для подключения к LongPoll серверу может истечь
  # через некоторое время, сервер вернёт параметр failed:
  # {failed: 2}
  #
  # в таком случае требуется переспросить его,
  # используя метод messages.getLongPollServer
  #
  if params['failed'] == 2
    puts "[INFO] Re-initilize Long Pool Server"

    begin
      resp = vk.api.messages_getLongPollServer
      key, server, ts = resp['key'], resp['server'], resp['ts']
    rescue Vkontakte::ApiError => err
      if err.code == 5
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
        user = vk.api.users_get(:user_ids => uid, :fields => 'sex').first['items']
      rescue Vkontakte::ApiError => err
        if err.code == 5
          puts "[ERROR] #{err.message}"
          puts "[INFO] Getting a new access_token"
          vk.login!(email, pass, 'messages')
          retry
        end
      end
      puts e if user.nil?
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
  # Сохранение нового значения ts
  ts = params['ts']
end
