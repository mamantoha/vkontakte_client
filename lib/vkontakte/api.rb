module Vkontakte
  class API
    attr_reader :access_token, :api_version
    attr_accessor :lang

    def initialize(access_token = nil, api_version: '', lang: 'ru')
      @access_token = access_token
      @api_version = api_version
      @lang = lang
    end

    # http://vk.com/dev/api_requests
    #
    # Перехват неизвестных методов для делегирования серверу ВКонтакте.
    #
    # Выполняет вызов метода API ВКонтакте.
    # * `method`: название метода из списка функций API
    # * `params`: параметры соответствующего метода API
    #
    # Следует заметить, что название вызываемих методов оформлены в стиле Ruby.
    # для вызова метода API ВКонтакте `friends.get`, вам необходиме передать `method='friends_get'`
    #
    # Возвращаемое значение: хэш с результатами вызова.
    # Генерируемые исключения: `Vkontakte::API::Error` если сервер ВКонтакте вернул ошибку.
    #
    def method_missing(method, *params)
      method_name = method.to_s.split('_').join('.')
      response = execute(method_name, *params)
      if response['error']
        error_code = response['error']['error_code']
        error_msg  = response['error']['error_msg']
        raise Vkontakte::API::Error.new(method_name, error_code, error_msg, params)
      end

      return response['response']
    end

    private

    def execute(method_name, params = {})
      params.merge!({ access_token: @access_token, lang: @lang, v: @api_version, https: '1' })

      url = "https://api.vk.com/method/#{method_name}"
      uri = URI(url)
      uri.query = URI.encode_www_form(params)

      request = Net::HTTP::Get.new(uri.request_uri)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }

      return JSON.parse(response.body)
    end

  end
end
