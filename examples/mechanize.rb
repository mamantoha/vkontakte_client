require 'bundler'
Bundler.setup :default

require 'mechanize'
require 'logger'

email = ARGV[0]
pass  = ARGV[1]

client_id     = '5135875'
redirect_uri  = 'https://oauth.vk.com/blank.html'
display       = 'mobile'
scope         = 'friends,audio,video'
response_type = 'token'
v             = '5.45'

# https://vk.com/dev/auth_mobile
puts "Открытие диалога авторизации"
url = "https://oauth.vk.com/oauth/authorize?client_id=#{client_id}&display=#{display}&redirect_uri=#{redirect_uri}&scope=#{scope}&response_type=#{response_type}&v=#{v}"
puts url


# puts Mechanize::VERSION
# log = Logger.new($stderr)
# log.level = Logger::DEBUG

agent = Mechanize.new do |a|
  a.user_agent_alias = 'Linux Firefox'
  a.follow_meta_refresh
  # a.verify_mode = OpenSSL::SSL::VERIFY_NONE
  # a.log = log
end

# agent.agent.http.debug_output = $stderr

page = agent.get(url)

login_form = page.forms.first
login_form.email = email
login_form.pass = pass
page = login_form.submit

unless page.search('.service_msg_warning').empty?
  raise('Invalid login or password.')
end

if page.uri.path == "/authorize"
  puts "Разрешение доступа"
  gain_access_form = page.forms.first
  page = gain_access_form.submit
end


# https://oauth.vk.com/blank.html#access_token=398ef517c9552129ec0f4df40ac483f9a29dd8f309f72323846deb40ee8799b38138cff939762c979c093&expires_in=86400&user_id=83380724
gragment_regexp = /\Aaccess_token=(?<access_token>.*)&expires_in=(?<expires_in>\d+)&user_id=(?<user_id>\d*)\z/
auth_params = page.uri.fragment.match(gragment_regexp)
if auth_params
  puts "access_token = #{auth_params[:access_token]}"
else
  byebug
end
