# frozen_string_literal: true

require 'vkontakte_client'

if $PROGRAM_NAME == __FILE__
  CLIENT_ID = '5987497'

  email = ARGV[0]
  pass  = ARGV[1]

  vk = Vkontakte::Client.new(CLIENT_ID)

  vk.login!(email, pass, open_captcha: true, permissions: 'friends')
  vk_api = vk.api

  friends_requests_ids = vk_api.friends_getRequests(need_viewed: 1, out: 0)['items']

  current_user = vk_api.users_get(fields: 'counters').first

  puts "User: #{current_user['first_name']} #{current_user['last_name']}"
  puts "Friends: #{current_user['counters']['friends']}"
  puts "Online Friends: #{current_user['counters']['online_friends']}"
  puts "Friends requests: #{friends_requests_ids.size}"
  puts "Subscriptions: #{current_user['counters']['subscriptions']}"
end
