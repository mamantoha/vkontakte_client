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

  vk.login!(email, pass, open_captcha: true, permissions: 'friends')
  vk_api = vk.api
  puts "Access token: #{vk.access_token}"

  friend_ids = vk_api.friends_getRequests(need_viewed: 1, out: 0)['items']
  puts "You have #{friend_ids.size} friends requests."

  friend_ids.each_slice(100) do |user_ids|
    user_ids.each do |user_id|
      print "Accept user with id `#{user_id}`"
      begin
        vk_api.friends_add(user_id: user_id)
        puts ' - OK'
      rescue Vkontakte::API::Error => ex
        if ex.error_code == 177
          vk_api.account_banUser(user_id: user_id)
        end
        puts ' - Skip'
      end
    end
  end
end
