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
  #a.log = log
end

#agent.agent.http.debug_output = $stderr

page = agent.get('http://vk.com/')
login_form = page.forms.first
login_form.email = email
login_form.pass = pass
page = login_form.submit
pp page
