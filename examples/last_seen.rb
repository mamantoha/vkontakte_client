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

  sorted_friends.each do |f|
    # Remove all friends you've never seen before
    #if f['last_seen']['time'] == 0
    #  resp = vk.api.friends_delete(uid: f['uid'])
    #  puts "Successfully remove #{f['first_name']} #{f['last_name']}" if resp == 1
    #end

    last_seen = Time.at(f['last_seen']['time'])
    puts "#{last_seen}: [#{f['uid']}] #{f['first_name']} #{f['last_name']}"
  end

end
