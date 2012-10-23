# encoding: utf-8

module Vkontakte
  # = Описание
  # Библиотека Vkontakte позволяет обращяться в API ВКонтакте
  #
  # == Пример
  #   require 'vkontakte'
  #   vk = Vkontakte::Client.new(APP_ID)
  #   vk.login!(email, pass)
  #   friends = vk.api.friends_get(:fields => 'online')
  #
  class Client
    attr_reader :api
    attr_reader :access_token, :user_id, :expires_in

    # Конструктор. Получает следующие аргументы:
    # * client_id: ID приложения ВКонтакте
    #
    # Для доступа к API ВКонтакте предусмотрен механизм клиентской авторизации на базе протокола OAuth 2.0.
    # В качестве клиента может выступать любое приложение, имеющее доступ к управлению Web-браузером.
    #
    # При клиентской авторизации ключ доступа к API `access_token` выдаётся приложению без
    # необходимости раскпытия секретного ключа приложения.
    #
    def initialize(client_id = nil)
      @client_id  = client_id
      @authorize  = false

      @api = Vkontakte::API.new
    end

    # Вход на сайт ВКонтакте
    # * email: логин пользователя
    # * pass: пароль
    # * scope: запрашиваемые права доступа приложения(http://vkontakte.ru/developers.php?o=-1&p=%CF%F0%E0%E2%E0%20%E4%EE%F1%F2%F3%EF%E0%20%EF%F0%E8%EB%EE%E6%E5%ED%E8%E9)
    #
    def login!(email, pass, scope = 'friends')
      redirect_uri  = 'http://oauth.vk.com/blank.html'
      display       = 'wap'
      response_type = 'token'

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

      response = Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') {|http|
        http.request(request)
      }

      l = /l=(.+?);/.match(response['set-cookie'])[1]
      p = /p=(.+?);/.match(response['set-cookie'])[1]

      # Получение куки
      url = response['location'] if response.code == '302'
      uri = URI(url)

      raise "Неверный логин или пароль" if /m=4/.match(uri.query)

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
      
      @api = Vkontakte::API.new(@access_token)
      @authorize = true

      return @access_token
    end

  end
end
