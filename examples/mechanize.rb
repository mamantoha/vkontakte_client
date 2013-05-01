# encoding: utf-8

require 'bundler'
Bundler.setup :default

require 'mechanize'
require 'logger'

email = ARGV[0]
pass  = ARGV[1]

puts Mechanize::VERSION

#log = Logger.new($stderr)
#log.level = Logger::DEBUG

agent = Mechanize.new do |a|
  a.user_agent_alias = 'Linux Firefox'
  a.follow_meta_refresh
  #a.verify_mode = OpenSSL::SSL::VERIFY_NONE
  #a.log = log
end

#agent.agent.http.debug_output = $stderr

page = agent.get('https://vk.com/')
login_form = page.form_with(name: 'login')
login_form.email = email
login_form.pass = pass
page = login_form.submit
pp page
