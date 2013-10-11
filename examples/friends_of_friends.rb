# encoding: utf-8

require 'bundler'
Bundler.setup :default

require 'pp'
require 'vkontakte'

puts Vkontakte::VERSION

if __FILE__ == $0
  CLIENT_ID = '1915108'

  email = ARGV[0]
  pass  = ARGV[1]

  vk = Vkontakte::Client.new(CLIENT_ID)
  vk.login!(email, pass)

  current_user = vk.api.users_get.first

  second_circle = {}
  second_circle.default = 0
  # [uid, uid, ...]
  my_friends = vk.api.friends_get['items']
  good_friends = 0
  bad_friends = 0

  my_friends.each_with_index do |uid, index|
    begin
      print "Parsing your friends: #{index + 1} of #{my_friends.size}. Good: #{good_friends}. Bad: #{bad_friends}\r"
      friends = vk.api.friends_get(:user_id => uid)['items']
      good_friends += 1
    rescue Vkontakte::ApiError => err
      # Permission to perform this action is denied by user
      bad_friends += 1
      next
    end
    friends.each { |f| second_circle[f] += 1 }
  end

  puts "\nComplete"

  # Отбросим друзей и людей, у которых только один общий знакомый
  second_circle.reject! {|uid, count| my_friends.include?(uid) || current_user['id'] == uid || count < 2}

  puts "Total people in 2nd circle: #{second_circle.size}"

  # Сортировка по количеству общих знакомых
  sorted_second_circle = second_circle.sort{|a, b| b[1]<=>a[1]} # <-- Hash sorting by value

  sorted_second_circle = sorted_second_circle[0...19]

  # sorted_second_circle           # => [['uid1', 1], ['uid2', 2], ['uid3', 3]]
  # sorted_second_circle.transpose # => [["uid1", "uid2", "uid3"], [1, 2, 3]]

  common_friends = vk.api.users_get(:user_ids => "#{sorted_second_circle.transpose[0].join(',')}")

  sorted_second_circle.each do |uid, count|
    f = common_friends.find{|f| f['id'] == uid} # <-- array of hashes: finding hash with value for key
    puts "[#{count}]: [#{f['id']}] #{f['first_name']} #{f['last_name']}"
  end

end
