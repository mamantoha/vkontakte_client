# frozen_string_literal: true

require 'bundler'
Bundler.setup :default

require 'pry'
require 'vkontakte'

puts Vkontakte::VERSION

if $PROGRAM_NAME == __FILE__
  CLIENT_ID = '5987497'

  email = ARGV[0]
  pass  = ARGV[1]

  vk = Vkontakte::Client.new(CLIENT_ID)

  # proxy = Vkontakte::Proxy.new(:socks, 'localhost', 9050)
  # vk = Vkontakte::Client.new(CLIENT_ID, proxy: proxy)

  vk.login!(email, pass, open_captcha: true, permissions: 'friends,wall')
  vk_api = vk.api
  puts "Access token: #{vk.access_token}"

  banned_ids = vk_api.newsfeed_getBanned['members']

  my_friends = []
  fr_count = 5000
  fr_offset = 0
  puts "Get friends"
  loop do
    fr = vk.api.friends_get(count: fr_count, offset: fr_offset * fr_count)['items']
    break if fr.empty?
    my_friends << fr
    fr_offset += 1
  end
  my_friends.flatten!

  my_requests = []
  fr_count = 1000
  fr_offset = 0
  puts "Received applications to friends"
  loop do
    fr = vk.api.friends_getRequests(count: fr_count, offset: fr_offset * fr_count, out: 0)['items']
    break if fr.empty?
    my_requests << fr
    fr_offset += 1
  end

  fr_count = 1000
  fr_offset = 0
  puts "Get requests sent by the me"
  loop do
    fr = vk.api.friends_getRequests(count: fr_count, offset: fr_offset * fr_count, out: 1)['items']
    break if fr.empty?
    my_requests << fr
    fr_offset += 1
  end

  my_requests.flatten!

  all_users = (my_friends | my_requests) - banned_ids

  puts "Clean news feed from #{all_users.size} new users"
  all_users.each_slice(100) do |user_ids|
    vk_api.newsfeed_addBan(user_ids: user_ids.join(','))
  end
  puts "#{vk_api.newsfeed_getBanned['members'].size} are banned."
end
