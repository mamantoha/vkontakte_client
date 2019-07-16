# frozen_string_literal: true

module Vkontakte
  # = Описание
  # Библиотека Vkontakte позволяет обращяться в API ВКонтакте
  #
  # == Пример
  #   require 'vkontakte'
  #   vk = Vkontakte::Client.new(APP_ID)
  #   vk.login!(email, pass, permissions: 'friends')
  #   friends = vk.api.friends_get(fields: 'online')
  #
  class Client
    attr_reader :api
    attr_reader :access_token, :user_id, :expires_in, :api_version

    # Конструктор. Получает следующие аргументы:
    # * client_id: ID приложения ВКонтакте
    #
    # Для доступа к API ВКонтакте предусмотрен механизм клиентской авторизации на базе протокола OAuth 2.0.
    # В качестве клиента может выступать любое приложение, имеющее доступ к управлению Web-браузером.
    #
    # При клиентской авторизации ключ доступа к API `access_token` выдаётся приложению без
    # необходимости раскпытия секретного ключа приложения.
    #
    def initialize(
      client_id = nil,
      api_version: Vkontakte::API_VERSION,
      proxy: nil,
      timeout: 60
    )
      @client_id = client_id
      @api_version = api_version
      @proxy = proxy
      @timeout = timeout
      @authorize = false

      @api = Vkontakte::API.new
    end

    # Вход на сайт ВКонтакте
    # * email: логин пользователя
    # * pass: пароль
    # * permissions: запрашиваемые права доступа приложения(http://vk.com/dev/permissions)
    #
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

      agent = Mechanize.new do |a|
        a.user_agent_alias = 'Linux Firefox'
        a.follow_meta_refresh

        a.agent.set_socks(@proxy.addr, @proxy.port) if @proxy&.socks?
        a.agent.set_proxy(@proxy.addr, @proxy.port) if @proxy&.http?
      end

      # https://vk.com/dev/implicit_flow_user
      #
      # Открытие диалога авторизации OAuth
      #
      query_string = query.map { |k, v| "#{k}=#{v}" }.join('&')
      url = "https://oauth.vk.com/authorize?#{query_string}"
      puts url

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

    def get_token(page)
      gragment_regexp = /\Aaccess_token=(?<access_token>.*)&expires_in=(?<expires_in>\d+)&user_id=(?<user_id>\d*)\z/
      auth_params = page.uri.fragment.match(gragment_regexp)

      return false unless auth_params

      @access_token = auth_params[:access_token]
      @user_id      = auth_params[:user_id]
      @expires_in   = auth_params[:expires_in]

      @api = Vkontakte::API.new(
        @access_token,
        proxy: @proxy,
        api_version: @api_version,
        timeout: @timeout
      )

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
      captcha = STDIN.gets.chomp

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
