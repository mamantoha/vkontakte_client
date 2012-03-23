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

  vk = Vkontakte::Client.new(CLIENT_ID, CLIENT_SECRET)
  vk.login!(email, pass)

  # http://vkontakte.ru/developers.php?o=-1&p=friends.get
  tb = Time.now
  friends = vk.api.friends_get(count: 20, order: 'hints', fields: 'online,last_seen')

  friends.each do |f|
    last_seen = Time.at(f['last_seen']['time'])
    puts "[#{f['uid']}] -#{last_seen}- #{f['first_name']} #{f['last_name']}" unless f['online'] == 1
  end

end
