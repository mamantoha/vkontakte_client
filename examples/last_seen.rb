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
  friends = vk.api.friends_get(fields: 'online,last_seen')

  # sort an array of hashes by a value in the hash
  sorted_friends = friends.sort_by {|k| k['last_seen']['time']}

  sorted_friends.last(20).each do |f|
    last_seen = Time.at(f['last_seen']['time'])
    puts "#{last_seen}: #{f['first_name']} #{f['last_name']}" unless f['online'] == 1
  end

end
