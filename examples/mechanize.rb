# encoding: utf-8

require 'mechanize'
require 'oauth2'
require 'logger'

email = 'anton.linux@gmail.com'
pass  = ''

api_secret = 'BsCEIfRxoDFZU8vZJ65v'
app_id     = '1915108'
scope      = 'friends'

client = OAuth2::Client.new(
  app_id,
  api_secret,
  :site          => 'https://api.vk.com/',
  :token_url     => '/oauth/token',
  :authorize_url => '/oauth/authorize'
)

auth_url = client.auth_code.authorize_url(
  :redirect_uri => 'http://api.vk.com/blank.html',
  :scope        => scope,
  :display      => 'wap'
)

agent = Mechanize.new { |a|
  a.user_agent_alias = 'Linux Konqueror'
  #a.log = Logger.new($stdout)
  #a.agent.http.debug_output = $stderr
}

# Открытие диалога авторизации OAuth
login_page = agent.get(auth_url)

login_form       = login_page.forms.first
login_form.email = email
login_form.pass  = pass

verify_page = login_form.submit

if verify_page.uri.path == '/oauth/authorize'
  if /m=4/.match(verify_page.uri.query)
    raise "Incorrect login or password"
  elsif /s=1/.match(verify_page.uri.query)
    grant_access_page = verify_page.forms.first.submit
  end
else
  grant_access_page = verify_page
end

code = /code=(?<code>.*)/.match(grant_access_page.uri.query)['code']
puts code
