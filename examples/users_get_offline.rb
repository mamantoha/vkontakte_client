# -*- encoding: utf-8 -*-

require 'bundler'
Bundler.setup :default

require 'vkontakte'

puts Vkontakte::VERSION

uids = ['strutynska', 'amaminov']

=begin
@client = OAuth2::Client.new(
  nil,
  nil,
  :site => 'https://api.vk.com/',
)

token = OAuth2::AccessToken.new(@client, 'token')

puts token.get( '/method/users.get', :params => { uids: uids.join(','), fields: 'online,last_seen' } ).parsed
=end

vk = Vkontakte::Client.new(nil, nil)

puts vk.api.users_get(uids: uids.join(','), fields: 'online,last_seen')

