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
    def initialize(client_id = nil, api_version: '5.2')
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

      # Открытие диалога авторизации OAuth
      # http://vk.com/dev/auth_mobile
      #
      url = "https://oauth.vk.com/oauth/authorize?"
      uri = URI(url)
      uri.query = URI.encode_www_form(query)

      request = Net::HTTP::Get.new(uri.request_uri)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true){ |http| http.request(request) }

      # Парсим ответ
      params = {
        _origin: response.body[/name="_origin" value="(.+?)"/, 1],
        ip_h:    response.body[/name="ip_h" value="(.+?)"/, 1],
        to:      response.body[/name="to" value="(.+?)"/, 1]
      }

      # Отправка формы
      url = 'https://login.vk.com/?act=login&soft=1&utf8=1'
      uri = URI(url)

      params.merge!({ email: email, pass: pass})

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true){ |http| http.request(request) }

      # Получение куки
      url = response['location'] if response.code == '302'
      uri = URI(url)

      raise "Неверный логин или пароль" if /m=4/.match(uri.query)

      l = /l=(.+?);/.match(response['set-cookie'])[1]
      p = /p=(.+?);/.match(response['set-cookie'])[1]

      request = Net::HTTP::Get.new(uri.request_uri)

      response = Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') {|http|
        http.request(request)
      }

      cookie = response['set-cookie']
      remixsid = cookie[/remixsid=(.+?);/, 1]

      # Установка куки
      header = { "Cookie" => "remixsid=#{remixsid};l=#{l};p=#{p}" }

      url = response['location'] if response.code == '302'
      uri = URI(url)

      request = Net::HTTP::Get.new(uri.request_uri, header)

      response = Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') {|http|
        http.request(request)
      }

      # Получение access_token
      if response.code == '302'
        url = response['location']
        get_token(url)
      elsif response.code == '200'
        url = response.body[/<form method="post" action="(.+?)"/i, 1]
        uri = URI(url)

        # Разрешаем доступ и отправляем форму
        request = Net::HTTP::Post.new(uri.request_uri, header)

        response = Net::HTTP.start(uri.host, uri.port,
          :use_ssl => uri.scheme == 'https') {|http|
          http.request(request)
        }

        if response.code == '302'
          url = response['location']
          get_token(url)
        end
      end

    end

    def authorized?
      @authorize ? true : false
    end

    private

    def get_token(url)
      uri = URI(url)
      params = Hash[URI.decode_www_form(uri.fragment)]

      @access_token = params['access_token']
      @user_id      = params['user_id']
      @expires_in   = params['expires_in']

      @api = Vkontakte::API.new(@access_token, api_version: @api_version)
      @authorize = true

      return @access_token
    end

  end
end
