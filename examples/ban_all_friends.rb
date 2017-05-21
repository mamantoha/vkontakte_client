# frozen_string_literal: true

require 'bundler'
Bundler.setup :default

require 'pry'
require 'vkontakte'

puts Vkontakte::VERSION

if __FILE__ == $PROGRAM_NAME
  CLIENT_ID = '5987497'

  email = ARGV[0]
  pass  = ARGV[1]

  proxy = Vkontakte::Proxy.new(:socks, 'localhost', 9050)

  # vk = Vkontakte::Client.new(CLIENT_ID)
  vk = Vkontakte::Client.new(CLIENT_ID, proxy: proxy)

  vk.login!(email, pass, open_captcha: true, permissions: 'friends,wall')
  vk_api = vk.api
  puts "Access token: #{vk.access_token}"

  friend_ids = vk_api.friends_get['items']

  puts 'Запрещает показывать новости от всех друзей'
  friend_ids.each_slice(100) do |user_ids|
    vk_api.newsfeed_addBan(user_ids: user_ids.join(','))
  end
  puts vk_api.newsfeed_getBanned
end
