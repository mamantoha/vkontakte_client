# -*- encoding: utf-8 -*-

require 'oauth2'
require 'mechanize'

# = Synopsis
# The library is used
#
# == Example
#   require 'rubygems'
class Client
  attr_reader :api

  ##
  # The version of <> you are using
  VERSION = '1.0'

  class Error < RuntimeError
  end

  def initialize(client_id, client_secret)
    @client_id     = client_id
    @client_secret = client_secret
    @authorize     = false
    @api           = nil

    # http://vkontakte.ru/developers.php?o=-1&p=%C0%E2%F2%EE%F0%E8%E7%E0%F6%E8%FF
    @client = OAuth2::Client.new(client_id, client_secret,
                                 :site              => 'https://api.vk.com/',
                                 :access_token_path => '/oauth/token',
                                 :authorize_path    => '/oauth/authorize',
                                 :parse_json        => true)


  end

  # http://vkontakte.ru/developers.php?o=-1&p=%CF%F0%E0%E2%E0%20%E4%EE%F1%F2%F3%EF%E0%20%EF%F0%E8%EB%EE%E6%E5%ED%E8%E9
  #
  def login!(email, pass, scope = 'friends')
    agent = Mechanize.new{|agent| agent.user_agent_alias = 'Linux Konqueror'}

    auth_url = @client.web_server.authorize_url(:redirect_uri => 'http://api.vk.com/blank.html', :scope => scope, :display => 'wap')

    login_page = agent.get(auth_url)

    login_form = login_page.forms.first
    login_form.email = email
    login_form.pass  = pass

    verify_page = login_form.submit

    if verify_page.uri.path == '/oauth/authorize'
      if /m=4/.match(verify_page.uri.query)
        raise Error, "Вказано невірний логін або пароль."
      elsif /s=1/.match(verify_page.uri.query)
        grant_access_page = verify_page.forms.first.submit
      end
    else
      grant_access_page = verify_page
    end

    code = /code=(?<code>.*)/.match(grant_access_page.uri.fragment)['code']

    @access_token = @client.web_server.get_access_token(code)
    @access_token.token_param = 'access_token'

    @api = API.new(@access_token)
    @authorize = true
  end

  def authorized?
    @authorize ? true : false
  end

end

class API
  def initialize(access_token)
    @access_token = access_token
  end

  def method_missing(method, *args)
    vk_method = method.to_s.split('_').join('.')
    response = execute(vk_method, *args)
    if response['error']
      raise "Error in `#{vk_method}': #{response['error']['error_code']}: #{response['error']['error_msg']}"
    end

    return response['response']
  end

  private

  # http://vkontakte.ru/developers.php?o=-1&p=%C2%FB%EF%EE%EB%ED%E5%ED%E8%E5%20%E7%E0%EF%F0%EE%F1%EE%E2%20%EA%20API
  def execute(method, params = {})
    url = "/method/"
    url << method
    url << "?"
    params.each{|key, value| url << "#{key}=#{value}&"}

    @access_token.get(url)
  end

end
