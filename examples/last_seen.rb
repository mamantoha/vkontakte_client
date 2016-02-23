require 'bundler'
Bundler.setup :default

require 'byebug'
require 'vkontakte'

puts Vkontakte::VERSION

if __FILE__ == $0
  CLIENT_ID = '5135875'

  email = ARGV[0]
  pass  = ARGV[1]

  vk = Vkontakte::Client.new(CLIENT_ID)
  vk.login!(email, pass)

  # http://vkontakte.ru/developers.php?o=-1&p=friends.get
  iam     = vk.api.users_get(user_ids: vk.user_id, fields: 'online,last_seen').first
  friends = vk.api.friends_get(fields: 'online,last_seen')['items']
  friends << iam

  # sort an array of hashes by a value in the hash
  sorted_friends = friends.sort_by { |k| k['last_seen'] ? k['last_seen']['time'] : 0 }

  sorted_friends.each do |f|
    last_seen = f['last_seen'] ? Time.at(f['last_seen']['time']) : 'Temporarily suspended'
    puts "#{last_seen}: [#{f['id']}] #{f['first_name']} #{f['last_name']}"
  end

end
