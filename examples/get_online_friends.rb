# -*- encoding: utf-8 -*-

require_relative '../lib/vkontakte'

APP_ID = '1915108'

email = 'anton.linux@gmail.com'
pass = ''

# Авторизація користувача за допомогою Desktop API
vk = VK::DesktopAuth.new(APP_ID)
vk.login!(email, pass)

mid, sid, secret = vk.mid, vk.sid, vk.secret

api = VK::API.new(APP_ID, mid, sid, secret)

#=begin
# 1)
# http://vkontakte.ru/developers.php?o=-1&p=friends.get
tb = Time.now
friends = api.friends_get(:fields => 'online')
friends_online = friends.select {|friend| friend['online'] == 1}

puts "Online friends [#{friends_online.size}]:"
friends_online.each{|f| puts "[#{f['uid']}] #{f['first_name']} #{f['last_name']}"}
#=end

=begin
# 2)
# http://vkontakte.ru/developers.php?o=-1&p=friends.getOnline
uids_online = api.friends_getOnline
friends_online = api.getProfiles(:uids => "#{uids_online.join(',')}")
puts "Online friends [#{friends_online.size}]:"
friends_online.each{|f| puts "[#{f['uid']}] #{f['first_name']} #{f['last_name']}"}
=end
