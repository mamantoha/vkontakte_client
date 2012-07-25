# encoding: utf-8

require 'bundler'
Bundler.setup :default

require 'vkontakte'

puts Vkontakte::VERSION

if __FILE__ == $0
  CLIENT_ID = '1915108'

  email = ARGV[0]
  pass  = ARGV[1]

  vk = Vkontakte::Client.new(CLIENT_ID)
  vk.login!(email, pass)

  friends = vk.api.friends_get(:fields => 'online')
  friends_online = friends.select {|friend| friend['online'] == 1}

  puts "Online friends [#{friends_online.size}]:"
  friends_online.each{|f| puts "[#{f['uid']}] #{f['first_name']} #{f['last_name']}"}
end
