# frozen_string_literal: true

require 'bundler'
Bundler.setup :default

require 'vkontakte_client'

puts Vkontakte::VERSION

uids = %w[strutynska amaminov]

# vk = Vkontakte::Client.new
# puts vk.authorized?
# puts vk.api.users_get(uids: uids.join(','), fields: 'online,last_seen')

api = Vkontakte::API.new
puts api.users_get(uids: uids.join(','), fields: 'online,last_seen')
