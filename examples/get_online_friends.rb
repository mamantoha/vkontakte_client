# frozen_string_literal: true

require 'bundler'
Bundler.setup :default

require 'vkontakte'

puts Vkontakte::VERSION

if $PROGRAM_NAME == __FILE__
  CLIENT_ID = '5987497'
  # Авторизация по логину и паролю
  email = ARGV[0]
  pass  = ARGV[1]
  vk = Vkontakte::Client.new(CLIENT_ID)
  vk.login!(email, pass, open_captcha: true)

  puts "access_token: #{vk.access_token}"
  puts "api_version: #{vk.api_version}"

  vk.api.lang = 'en'
  friends = vk.api.friends_get(fields: 'online')

  # Использование токена
  # access_token = ARGV[0]
  # api = Vkontakte::API.new(access_token)
  # friends = api.friends_get(fields:  'online')

  friends_online = friends['items'].select { |item| item['online'] == 1 }

  puts "Online friends [#{friends_online.size}]:"
  friends_online.each do |f|
    mobile = f['online_mobile'] == 1 ? '[mobile]' : ''
    puts "[#{f['id']}] #{f['first_name']} #{f['last_name']} #{mobile}"
  end
end
