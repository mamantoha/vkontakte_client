# encoding: utf-8

module Vkontakte
  class API

    def initialize(access_token = nil)
      @access_token = access_token
    end

    # http://vk.com/pages?oid=-1&p=%D0%92%D1%8B%D0%BF%D0%BE%D0%BB%D0%BD%D0%B5%D0%BD%D0%B8%D0%B5_%D0%B7%D0%B0%D0%BF%D1%80%D0%BE%D1%81%D0%BE%D0%B2_%D0%BA_API
    #
    # Перехват неизвестных методов для делегирования серверу ВКонтакте.
    #
    # Выполняет вызов метода API ВКонтакте.
    # * `method`: имя метода ВКонтакте.
    # * `params`: хэш с именованными аргументами метода ВКонтакте.
    #
    # Следует заметить, что название вызываемих методов оформлены в стиле Ruby.
    # для вызова метода API ВКонтакте `friends.get`, вам необходиме передать `method='friends_get'`
    #
    # Возвращаемое значение: хэш с результатами вызова.
    # Генерируемые исключения: `Vkontakte::VkException` если сервер ВКонтакте вернул ошибку.
    #
    def method_missing(method, *params)
      vk_method = method.to_s.split('_').join('.')
      response = execute(vk_method, *params)
      if response['error']
        error_code = response['error']['error_code']
        error_msg  = response['error']['error_msg']
        raise Vkontakte::VkException.new(vk_method, error_code, error_msg), "Error in `#{vk_method}': #{error_code}: #{error_msg}"
      end

      return response['response']
    end

    private

    def execute(method, params = {})
      params.merge!(access_token: @access_token)
      
      url = "https://api.vk.com/method/#{method}"
      uri = URI(url)
      uri.query = URI.encode_www_form(params)

      request = Net::HTTP::Get.new(uri.request_uri)

      response = Net::HTTP.start(uri.host, uri.port,
        :use_ssl => uri.scheme == 'https') {|http|
        http.request(request)
      }

      return JSON.parse(response.body)
    end
  end
end
