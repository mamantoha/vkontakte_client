module Vkontakte
  class API
    def initialize(access_token)
      # OAuth2::AccessToken
      @access_token = access_token
    end

    def method_missing(method, *args)
      vk_method = method.to_s.split('_').join('.')
      response = execute(vk_method, *args).parsed
      if response['error']
        error_code = response['error']['error_code']
        error_msg  = response['error']['error_msg']
        raise Vkontakte::VkException.new(vk_method, error_code, error_msg), "Error in `#{vk_method}': #{error_code}: #{error_msg}"
      end

      return response['response']
    end

    private

    # http://vkontakte.ru/developers.php?o=-1&p=%C2%FB%EF%EE%EB%ED%E5%ED%E8%E5%20%E7%E0%EF%F0%EE%F1%EE%E2%20%EA%20API
    def execute(method, params = {})
      method = "/method/#{method}"

      @access_token.get(method, :params => params, :parce => :json)
    end

  end
end
