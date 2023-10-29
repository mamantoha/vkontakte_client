# frozen_string_literal: true

module Vkontakte
  # :nodoc:
  class Client
    attr_reader :api, :access_token, :user_id, :expires_in, :api_version

    # Implicit Flow for User Access Token
    #
    # https://vk.com/dev/implicit_flow_user
    def initialize(
      client_id = nil,
      api_version: Vkontakte::API_VERSION,
      proxy: nil,
      timeout: 60,
      log: false
    )
      @client_id = client_id
      @api_version = api_version
      @proxy = proxy
      @timeout = timeout
      @authorize = false
      @log = log

      @api = Vkontakte::API.new
    end

    def login!(email, pass, open_captcha: false, permissions: '')
      @email = email
      @pass = pass

      redirect_uri  = 'https://oauth.vk.com/blank.html'
      display       = 'mobile'
      response_type = 'token'

      query = {
        client_id: @client_id,
        redirect_uri: redirect_uri,
        display: display,
        scope: permissions,
        response_type: response_type,
        v: api_version
      }

      # Opening Authorization Dialog
      #
      query_string = query.map { |k, v| "#{k}=#{v}" }.join('&')
      url = "https://oauth.vk.com/authorize?#{query_string}"

      page = agent.get(url)

      login_form = page.forms.first
      login_form.email = @email
      login_form.pass = @pass
      page = login_form.submit

      raise('Invalid login or password.') unless page.search('.service_msg_warning').empty?

      page = submit_gain_access_form(page, open_captcha) if page.uri.path == '/authorize'

      get_token(page)
    end

    def authorized?
      @authorize ? true : false
    end

    private

    def agent
      @agent ||= Mechanize.new do |a|
        a.user_agent = 'Opera/9.80 (Android; Opera Mini/7.5.33942/191.308; U; en) Presto/2.12.423 Version/12.16'
        a.follow_meta_refresh
        a.log = Logger.new($stdout) if @log

        a.agent.set_socks(@proxy.addr, @proxy.port) if @proxy&.socks?
        a.agent.set_proxy(@proxy.addr, @proxy.port) if @proxy&.http?
      end
    end

    def initialize_vkontakte_api(auth_params)
      return @api if authorized?

      @access_token = auth_params[:access_token]
      @user_id      = auth_params[:user_id]
      @expires_in   = auth_params[:expires_in]

      @api = Vkontakte::API.new(
        @access_token,
        proxy: @proxy,
        api_version: @api_version,
        timeout: @timeout
      )
    end

    def get_token(page)
      auth_regexp = /access_token=(?<access_token>.*)&expires_in=(?<expires_in>\d+)&user_id=(?<user_id>\d*)\z/

      return false unless page.uri.path == '/auth_redirect'

      query_params = URI.decode_www_form(page.uri.query).to_h
      authorize_url = CGI.unescape(query_params['authorize_url'])

      auth_params = authorize_url.match(auth_regexp)

      return false unless auth_params

      initialize_vkontakte_api(auth_params)

      @authorize = true

      @access_token
    end

    def submit_gain_access_form(page, open_captcha)
      form = page.forms.first

      return form.submit unless form.has_key?('captcha_key')

      raise('Captcha needed.') unless open_captcha

      captcha_img = page.search('img[id=captcha]').first

      puts 'Captcha needed.'
      puts "Open url: #{captcha_img['src']}"
      print 'Enter captch: '
      captcha = $stdin.gets.chomp

      form.pass = @pass
      form.captcha_key = captcha
      allow_page = form.submit

      allow_form = allow_page.forms.first
      allow_page = allow_form.submit if allow_form&.buttons&.detect { |btn| btn.value == 'Allow' }

      raise('Invalid captcha.') unless allow_page.uri.path == '/blank.html'

      allow_page
    end
  end
end
