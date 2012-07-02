# -*- encoding: utf-8 -*-

require 'net/http'

module Vkontakte
  # = Описание
  # Библиотека Vkontakte позволяет обращяться в API ВКонтакте
  #
  # == Пример
  #   require 'vkontakte'
  #   vk = Vkontakte::Client.new(APP_ID, API_SECRET)
  #   vk.login!(email, pass)
  #   friends = vk.api.friends_get(:fields => 'online')
  #
  class Client
    attr_reader :api

    # Конструктор. Получает следующие аргументы:
    # * app_id: ID приложения ВКонтакте
    # * api_secret: Ключ приложения со страницы настроек
    #
    # Для доступа к API ВКонтакте предусмотрен механизм клиентской авторизации на базе протокола OAuth 2.0.
    # В качестве клиента может выступать любое приложение, имеющее доступ к управлению Web-браузером.
    #
    def initialize(client_id, api_secret)
      @client_id  = client_id
      @api_secret = api_secret
      @authorize  = false

      # http://vkontakte.ru/developers.php?o=-1&p=%C0%E2%F2%EE%F0%E8%E7%E0%F6%E8%FF
      @oauth2_client = OAuth2::Client.new(
        @client_id,
        @api_secret,
        :site          => 'https://api.vk.com/',
        :token_url     => '/oauth/token',
        :authorize_url => '/oauth/authorize'
      )

      access_token = OAuth2::AccessToken.new(@oauth2_client, 'token')
      @api = Vkontakte::API.new(access_token)
    end

    # Вход на сайт ВКонтакте
    # * email: логин пользователя
    # * pass: пароль
    # * scope: запрашиваемые права доступа приложения(http://vkontakte.ru/developers.php?o=-1&p=%CF%F0%E0%E2%E0%20%E4%EE%F1%F2%F3%EF%E0%20%EF%F0%E8%EB%EE%E6%E5%ED%E8%E9)
    #
    def login!(email, pass, scope = 'friends')
      redirect_uri  = 'http://oauth.vk.com/blank.html'
      display       = 'wap'
      response_type = 'code'

      # Открытие диалога авторизации
      # http://vk.com/developers.php?id=-1_37230422&s=1
      url = "http://oauth.vk.com/oauth/authorize?client_id=#{@client_id}&scope=#{scope}&redirect_uri=#{redirect_uri}&display=#{display}&response_type=#{response_type}&_hash=0"
      uri = URI(url)

      request = Net::HTTP::Get.new(uri.request_uri)

      response = Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') {|http|
        http.request(request)
      }

      # Парсим ответ
      params = {
        :q             => /name="q" value="(.+?)"/.match(response.body)[1],
        :from_host     => /name="from_host" value="(.+?)"/.match(response.body)[1],
        :from_protocol => /name="from_protocol" value="(.+?)"/.match(response.body)[1],
        :ip_h          => /name="ip_h" value="(.+?)"/.match(response.body)[1],
        :to            => /name="to" value="(.+?)"/.match(response.body)[1]
      }

      # Отправка формы
      url = 'https://login.vk.com/?act=login&soft=1&utf8=1'
      uri = URI(url)

      params.merge!({ email: email, pass: pass})

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)

      response = Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') {|http|
        http.request(request)
      }

      if response.code == '302'
        url = response.header['Location']
      end

      # Разрещение доступа
      uri = URI(url)

      raise "Неверный логин или пароль" if /m=4/.match(uri.query)

      request = Net::HTTP::Get.new(uri.request_uri)

      response = Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') {|http|
        http.request(request)
      }

      if response.code == '302'
        url = response.header['Location']
      end

      cookie = response['set-cookie']
      remixsid = /remixsid=(.+?);/.match(cookie)[1]

      # Получение code
      uri = URI(url)
      header = { "Cookie" => 'remixsid=' + remixsid }

      request = Net::HTTP::Get.new(uri.request_uri, header)

      response = Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') {|http|
        http.request(request)
      }

      if response.code == '302'
        url = response.header['Location']
        code = /code=(.+)$/.match(url)[1]
      elsif response.code == '200'
        url = /<form method="POST" action="(.+?)"/.match(response.body)[1]
        uri = URI(url)

        header = { "Cookie" => 'remixsid=' + remixsid }
        
        # Разрешаем доступ и отправляем форму
        request = Net::HTTP::Post.new(uri.request_uri, header)

        response = Net::HTTP.start(uri.host, uri.port,
          :use_ssl => uri.scheme == 'https') {|http|
          http.request(request)
        }

        if response.code == '302'
          url = response.header['Location']
          code = /code=(.+)$/.match(url)[1]
        end
      end

      access_token = @oauth2_client.auth_code.get_token(code)
      access_token.options[:param_name] = 'access_token'
      access_token.options[:mode] = :query

      @api = Vkontakte::API.new(access_token)
      @authorize = true
    end

    def authorized?
      @authorize ? true : false
    end

  end
end
