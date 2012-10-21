# encoding: utf-8

require 'net/http'
require 'pp'

email = ARGV[0]
pass  = ARGV[1]

client_id     = '1915108'
scope         = 'friends'
redirect_uri  = 'http://oauth.vk.com/blank.html'
display       = 'wap'
response_type = 'token'

puts "Открытие диалога авторизации"
# http://vk.com/developers.php?id=-1_37230422&s=1
url = "http://oauth.vk.com/oauth/authorize?client_id=#{client_id}&scope=#{scope}&redirect_uri=#{redirect_uri}&display=#{display}&response_type=#{response_type}&_hash=0"
puts url
uri = URI(url)

request = Net::HTTP::Get.new(uri.request_uri)

response = Net::HTTP.start(uri.host, uri.port){ |http| http.request(request) }

puts "Парсим ответ"
params = {
  q:             response.body[/name="q" value="(.+?)"/, 1],
  from_host:     response.body[/name="from_host" value="(.+?)"/, 1],
  from_protocol: response.body[/name="from_protocol" value="(.+?)"/, 1],
  ip_h:          response.body[/name="ip_h" value="(.+?)"/, 1],
  to:            response.body[/name="to" value="(.+?)"/, 1]
}

puts "Отправка формы"
url = /<form method="POST" action="(.+?)"/.match(response.body)[1]
puts url
uri = URI(url)

params.merge!(email: email, pass: pass)

request = Net::HTTP::Post.new(uri.request_uri)
request.set_form_data(params)

response = Net::HTTP.start(uri.host, uri.port,
  :use_ssl => uri.scheme == 'https') {|http|
  http.request(request)
}

puts response.code
if response.code == '302'
  url = response['location']
end

puts "Разрешение доступа и получения куки"
uri = URI(url)
puts url

raise "Неверный логин или пароль" if /m=4/.match(uri.query)

request = Net::HTTP::Get.new(uri.request_uri)

response = Net::HTTP.start(uri.host, uri.port,
  :use_ssl => uri.scheme == 'https') {|http|
  http.request(request)
}

remixsid = /remixsid=(.+?);/.match(response['set-cookie'])[1]
header = { "Cookie" => 'remixsid=' + remixsid }

# если пользователь этого еще не делал(response.code == '200'), надо дать приложению права
puts response.code
if response.code == '302'
  url = response['location']
end

puts "Установка куки"
uri = URI(url)
puts url

request = Net::HTTP::Get.new(uri.request_uri, header)

response = Net::HTTP.start(uri.host, uri.port,
  :use_ssl => uri.scheme == 'https') {|http|
  http.request(request)
}

puts "Получения access_token"
puts response.code
if response.code == '302'
  url = response['location']
  puts url
  access_token = /access_token=(.+?)&/.match(url)[1]
elsif response.code == '200'
  url = /<form method="POST" action="(.+?)"/.match(response.body)[1]
  puts url
  uri = URI(url)

  # Разрешаем доступ и отправляем форму
  request = Net::HTTP::Post.new(uri.request_uri, header)

  response = Net::HTTP.start(uri.host, uri.port,
    :use_ssl => uri.scheme == 'https') {|http|
    http.request(request)
  }

  puts response.code
  if response.code == '302'
    url = response['location']
    access_token = /access_token=(.+?)&/.match(url)[1]
  end
end

puts url
puts 'access_token=' + access_token
