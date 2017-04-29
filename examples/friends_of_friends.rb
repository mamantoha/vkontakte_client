# frozen_string_literal: true

require 'bundler'
Bundler.setup :default

require 'pp'
require 'vkontakte'

puts Vkontakte::VERSION

if __FILE__ == $PROGRAM_NAME
  CLIENT_ID = '5987497'

  email = ARGV[0]
  pass  = ARGV[1]

  vk = Vkontakte::Client.new(CLIENT_ID)
  vk.login!(email, pass, permissions: 'friends')

  current_user = vk.api.users_get.first

  second_circle = {}
  second_circle.default = 0
  # [uid, uid, ...]
  my_friends = vk.api.friends_get(order: 'hints')['items']
  good_friends = 0
  bad_friends = 0

  my_friends.each_with_index do |uid, index|
    begin
      print "Parsing your friends: #{index + 1} of #{my_friends.size}. Good: #{good_friends}. Bad: #{bad_friends}\r"
      friends = vk.api.friends_get(user_id: uid)['items']
      good_friends += 1
    rescue Vkontakte::API::Error
      # Permission to perform this action is denied by user
      bad_friends += 1
      next
    end
    friends.each { |f| second_circle[f] += 1 }
  end

  puts "\nComplete"

  # Отбросим друзей и людей, у которых только один общий знакомый
  second_circle.reject! { |uid, count| my_friends.include?(uid) || current_user['id'] == uid || count < 2 }

  puts "Total people in 2nd circle: #{second_circle.size}"

  # Сортировка по количеству общих знакомых
  sorted_second_circle = second_circle.sort { |a, b| b[1] <=> a[1] } # <-- Hash sorting by value

  # информацию о отправленных заявках на добавление в друзья
  friends_requests = vk.api.friends_getRequests(out: 1, count: 1000)['items']

  # Отбросим людей которым уже послали приглашение в друзья
  sorted_second_circle.reject! { |arry| friends_requests.include?(arry[0]) }

  sorted_second_circle = sorted_second_circle[0...99]

  # sorted_second_circle           # => [['uid1', 1], ['uid2', 2], ['uid3', 3]]
  # sorted_second_circle.transpose # => [["uid1", "uid2", "uid3"], [1, 2, 3]]

  common_friends = vk.api.users_get(user_ids: sorted_second_circle.transpose[0].join(',').to_s)

  sorted_second_circle.each do |uid, count|
    begin
      user = vk.api.users_get(user_id: uid).first

      unless user['deactivated']
        friend = common_friends.find { |f| f['id'] == uid }
        puts "[#{count}]: [#{friend['id']}] #{friend['first_name']} #{friend['last_name']}"
        vk.api.friends_add(user_id: friend['id'])
      end
    rescue Vkontakte::API::Error => err
      puts err.message
      sleep 60
      retry
    end
  end

end
