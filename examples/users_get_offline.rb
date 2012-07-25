# encoding: utf-8

require 'bundler'
Bundler.setup :default

require 'vkontakte'

puts Vkontakte::VERSION

uids = ['strutynska', 'amaminov']

#vk = Vkontakte::Client.new
#puts vk.authorized?
#puts vk.api.users_get(uids: uids.join(','), fields: 'online,last_seen')

api = Vkontakte::API.new
puts api.users_get(uids: uids.join(','), fields: 'online,last_seen')
