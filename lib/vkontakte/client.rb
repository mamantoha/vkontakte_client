# -*- encoding: utf-8 -*-

require 'mechanize'
require 'logger'

module Vkontakte
  # = Synopsis
  # The library is used
  #
  # == Example
  #   require 'vkontakte'
  #   vk = Vkontakte::Client.new(CLIENT_ID, CLIENT_SECRET)
  #   vk.login!(email, pass)
  #   friends = vk.api.friends_get(:fields => 'online')
  class Client
    attr_reader :api

    def initialize(client_id, client_secret)
      @client_id     = client_id
      @client_secret = client_secret
      @authorize     = false
      @api           = nil

      # http://vkontakte.ru/developers.php?o=-1&p=%C0%E2%F2%EE%F0%E8%E7%E0%F6%E8%FF
      @client = OAuth2::Client.new(
        client_id,
        client_secret,
        :site          => 'https://api.vk.com/',
        :token_url     => '/oauth/token',
        :authorize_url => '/oauth/authorize'
      )

    end

    # http://vkontakte.ru/developers.php?o=-1&p=%CF%F0%E0%E2%E0%20%E4%EE%F1%F2%F3%EF%E0%20%EF%F0%E8%EB%EE%E6%E5%ED%E8%E9
    #
    def login!(email, pass, scope = 'friends')
      # Create a new mechanize object
      agent = Mechanize.new { |agent|
        agent.user_agent_alias = 'Linux Konqueror'
        agent.log = Logger.new($stdout)
      }

      auth_url = @client.auth_code.authorize_url(
        :redirect_uri => 'http://api.vk.com/blank.html',
        :scope        => scope,
        :display      => 'wap'
      )

      # Get the Vkontakte sing in page
      login_page = agent.get(auth_url)

      # Fill out the login form
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

      @access_token = @client.auth_code.get_token(code)
      @access_token.options[:param_name] = 'access_token'
      @access_token.options[:mode] = :query

      @api = Vkontakte::API.new(@access_token)
      @authorize = true
    end

    def authorized?
      @authorize ? true : false
    end

  end
end
