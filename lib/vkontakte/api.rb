module Vkontakte
  class API
    attr_reader :user_id

    def initialize(access_token)
      # if access_token.instance_of? OAuth2::AccessToken
      @access_token = access_token
      @user_id = @access_token.params['user_id']
    end

    # http://vkontakte.ru/developers.php?o=-1&p=%C2%FB%EF%EE%EB%ED%E5%ED%E8%E5%20%E7%E0%EF%F0%EE%F1%EE%E2%20%EA%20API
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
      response = execute(vk_method, *params).parsed
      if response['error']
        error_code = response['error']['error_code']
        error_msg  = response['error']['error_msg']
        raise Vkontakte::VkException.new(vk_method, error_code, error_msg), "Error in `#{vk_method}': #{error_code}: #{error_msg}"
      end

      return response['response']
    end

    private

    def execute(method, params = {})
      method = "/method/#{method}"
      @access_token.get(method, :params => params, :parce => :json)
    end

  end
end
