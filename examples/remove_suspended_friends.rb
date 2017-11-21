# frozen_string_literal: true

require 'bundler'
Bundler.setup :default

require 'vkontakte'

puts Vkontakte::VERSION

if $PROGRAM_NAME == __FILE__
  CLIENT_ID = '5987497'.freeze

  email = ARGV[0]
  pass  = ARGV[1]

  vk = Vkontakte::Client.new(CLIENT_ID)
  vk.login!(email, pass, permissions: 'friends')

  vk.api.account_getInfo

  # https://vk.com/dev/friends.get
  friends = vk.api.friends_get(fields: 'online,last_seen')['items']
  friends.each do |f|
    deactivated = f['deactivated'] == 'banned'
    if deactivated
      puts "Delete user with id `#{f['id']}`"
      vk.api.friends_delete(user_id: f['id'])
    end
  end
end
