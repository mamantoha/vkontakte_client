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

  suggestions = vk.api.friends_getSuggestions(filter: 'mutual')['items']
  suggestions.each do |user|
    begin
      sleep 1

      puts "Add [#{user['id']}] #{user['first_name']} #{user['last_name']}"
      vk.api.friends_add(user_id: user['id'])
    rescue Vkontakte::API::Error => err
      puts err.message

      case err.error_code
      when 1
        puts 'Come back tomorrow'
        break
      when *[175, 176]
        next
      else
        sleep 60
        retry
      end
    end

  end

end
