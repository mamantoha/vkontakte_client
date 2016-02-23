module Vkontakte
  # = Описание
  # Библиотека Vkontakte позволяет обращяться в API ВКонтакте
  #
  # == Пример
  #   require 'vkontakte'
  #   vk = Vkontakte::Client.new(APP_ID)
  #   vk.login!(email, pass, permission: 'friends')
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
    def initialize(client_id = nil, api_version: '5.45')
      @client_id  = client_id
      @api_version = api_version
      @authorize  = false

      @api = Vkontakte::API.new
    end

    # Вход на сайт ВКонтакте
    # * email: логин пользователя
    # * pass: пароль
    # * permissions: запрашиваемые права доступа приложения(http://vk.com/dev/permissions)
    #
    def login!(email, pass, permissions: 'friends')
      redirect_uri  = 'https://oauth.vk.com/blank.html'
      display       = 'mobile'
      response_type = 'token'

      query = {
        client_id:     @client_id,
        scope:         permissions,
        redirect_uri:  redirect_uri,
        display:       display,
        v:             api_version,
        response_type: response_type,
      }

      agent = Mechanize.new do |a|
        a.user_agent_alias = 'Linux Firefox'
        a.follow_meta_refresh
      end

      # Открытие диалога авторизации OAuth
      # http://vk.com/dev/auth_mobile
      #
      query_string = query.map{ |k,v| "#{k}=#{v}" }.join('&')
      url = "https://oauth.vk.com/oauth/authorize?#{query_string}"

      page = agent.get(url)

      login_form = page.forms.first
      login_form.email = email
      login_form.pass = pass
      page = login_form.submit

      unless page.search('.service_msg_warning').empty?
        raise('Invalid login or password.')
      end

      if page.uri.path == "/authorize"
        gain_access_form = page.forms.first
        page = gain_access_form.submit
      end

      return get_token(page)
    end

    def authorized?
      @authorize ? true : false
    end

    private

    def get_token(page)
      gragment_regexp = /\Aaccess_token=(?<access_token>.*)&expires_in=(?<expires_in>\d+)&user_id=(?<user_id>\d*)\z/
      auth_params = page.uri.fragment.match(gragment_regexp)
      if auth_params
        @access_token = auth_params[:access_token]
        @user_id      = auth_params[:user_id]
        @expires_in   = auth_params[:expires_in]

        @api = Vkontakte::API.new(@access_token, api_version: @api_version)
        @authorize = true

        return @access_token
      else
        return false
      end
    end

  end
end
