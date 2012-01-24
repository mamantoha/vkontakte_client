# -*- encoding: utf-8 -*-

require 'bundler'
Bundler.setup :default

require 'vkontakte'

puts Vkontakte::VERSION

if __FILE__ == $0
  CLIENT_SECRET = 'BsCEIfRxoDFZU8vZJ65v'
  CLIENT_ID     = '1915108'

  puts email = 'anton.linux@gmail.com'
  # Hide password
  print 'Password: '
  system "stty -echo"
  pass = $stdin.gets.chomp
  system "stty echo"

  #pass  = ARGV[0] || ''

  vk = Vkontakte::Client.new(CLIENT_ID, CLIENT_SECRET)
  vk.login!(email, pass)

#=begin
  # 1)
  # http://vkontakte.ru/developers.php?o=-1&p=friends.get
  tb = Time.now
  friends = vk.api.friends_get(:fields => 'online')
  friends_online = friends.select {|friend| friend['online'] == 1}

  puts "Online friends [#{friends_online.size}]:"
  friends_online.each{|f| puts "[#{f['uid']}] #{f['first_name']} #{f['last_name']}"}
#=end

=begin
  # 2)
  # http://vkontakte.ru/developers.php?o=-1&p=friends.getOnline
  uids_online = vk.api.friends_getOnline
  friends_online = vk.api.getProfiles(:uids => "#{uids_online.join(',')}")
  puts "Online friends [#{friends_online.size}]:"
  friends_online.each{|f| puts "[#{f['uid']}] #{f['first_name']} #{f['last_name']}"}
=end
end
