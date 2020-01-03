# frozen_string_literal: true

require 'bundler'
Bundler.setup :default

require 'vkontakte'

puts Vkontakte::VERSION

if $PROGRAM_NAME == __FILE__
  CLIENT_ID = '5987497'

  email = ARGV[0]
  pass  = ARGV[1]

  vk = Vkontakte::Client.new(CLIENT_ID)
  vk.login!(email, pass, permissions: 'friends', open_captcha: true)

  out_requests = []
  count = 1000
  offset = 0

  loop do
    fr = vk.api.friends_getRequests(count: count, offset: offset * count, out: 1)['items']
    break if fr.empty?

    out_requests << fr
    offset += 1
  end
  out_requests.flatten!

  out_requests_size = out_requests.size

  puts "You have #{out_requests_size} out requests."

  out_requests.each_with_index do |id, i|
    resp = vk.api.friends_delete(user_id: id)
    if resp['out_request_deleted'] == 1
      puts "[#{i + 1}/#{out_requests_size}] Succeess delete request to `#{id}`"
    else
      resp
    end
  end
end
