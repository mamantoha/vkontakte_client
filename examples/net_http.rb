# encoding: utf-8

require 'net/http'

email = 'anton.linux@gmail.com'
pass  = ARGV[0] || ''

client_id     = '1915108'
scope         = 'friends,audio'
redirect_uri  = 'http://oauth.vk.com/blank.html'
display       = 'wap'
response_type = 'code'

puts "Открытие диалога авторизации"
# http://vk.com/developers.php?id=-1_37230422&s=1
url = "http://oauth.vk.com/oauth/authorize?client_id=#{client_id}&scope=#{scope}&redirect_uri=#{redirect_uri}&display=#{display}&response_type=#{response_type}&_hash=0"
uri = URI(url)

request = Net::HTTP::Get.new(uri.request_uri)

response = Net::HTTP.start(uri.host, uri.port){ |http| http.request(request) }

# Парсим ответ
params = {
  :q             => /name="q" value="(.+?)"/.match(response.body)[1],
  :from_host     => /name="from_host" value="(.+?)"/.match(response.body)[1],
  :from_protocol => /name="from_protocol" value="(.+?)"/.match(response.body)[1],
  :ip_h          => /name="ip_h" value="(.+?)"/.match(response.body)[1],
  :to            => /name="to" value="(.+?)"/.match(response.body)[1]
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
  url = response.header['Location']
end

puts "Разрешение доступа"
uri = URI(url)
puts url

raise "Неверный логин или пароль" if /m=4/.match(uri.query)

request = Net::HTTP::Get.new(uri.request_uri)

response = Net::HTTP.start(uri.host, uri.port,
  :use_ssl => uri.scheme == 'https') {|http|
  http.request(request)
}

# если пользователь этого еще не делал(response.code == '200'), надо дать приложению права
puts response.code
if response.code == '302'
  url = response.header['Location']
end

cookie = response['set-cookie']
remixsid = /remixsid=(.+?);/.match(cookie)[1]

puts "Получение code"
uri = URI(url)
puts url

header = { "Cookie" => 'remixsid=' + remixsid }

request = Net::HTTP::Get.new(uri.request_uri, header)

response = Net::HTTP.start(uri.host, uri.port,
  :use_ssl => uri.scheme == 'https') {|http|
  http.request(request)
}

puts response.code
if response.code == '302'
  url = response.header['Location']
  code = /code=(.+)$/.match(url)[1]
elsif response.code == '200'
  url = /<form method="POST" action="(.+?)"/.match(response.body)[1]
  puts url
  uri = URI(url)

  header = { "Cookie" => 'remixsid=' + remixsid }
  
  # Разрешаем доступ и отправляем форму
  request = Net::HTTP::Post.new(uri.request_uri, header)

  response = Net::HTTP.start(uri.host, uri.port,
    :use_ssl => uri.scheme == 'https') {|http|
    http.request(request)
  }

  puts response.code
  if response.code == '302'
    url = response.header['Location']
    code = /code=(.+)$/.match(url)[1]
  end
end

puts 'code=' + code
