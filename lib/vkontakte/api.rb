# frozen_string_literal: true

module Vkontakte
  # Make Vkontakte API requests
  #
  class API
    attr_reader :access_token, :proxy, :api_version, :timeout
    attr_accessor :lang

    def initialize(
      access_token = nil,
      proxy: nil,
      api_version: Vkontakte::API_VERSION,
      lang: 'ru',
      timeout: 60
    )
      @access_token = access_token
      @proxy = proxy
      @api_version = api_version
      @lang = lang
      @timeout = timeout
    end

    def method_missing(method, *params)
      method_name = method.to_s.split('_').join('.')
      response = execute(method_name, *params)
      if response['error']
        error_code = response['error']['error_code']
        error_msg  = response['error']['error_msg']
        raise Vkontakte::API::Error.new(method_name, error_code, error_msg, params)
      end

      response['response']
    end

    private

    def execute(method_name, params = {})
      params.merge!(access_token: @access_token, lang: @lang, v: @api_version, https: '1')

      url = "https://api.vk.com/method/#{method_name}"

      response = make_request(url, params)

      JSON.parse(response.body)
    end

    def make_request(url, params)
      uri = URI(url)
      use_ssl = uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri)
      request.form_data = params

      if @proxy
        if @proxy.http?
          Net::HTTP.start(
            uri.hostname,
            uri.port,
            @proxy.addr,
            @proxy.port,
            use_ssl: use_ssl,
            read_timeout: timeout,
            open_timeout: timeout
          ) do |http|
            http.request(request)
          end
        elsif @proxy.socks?
          Net::HTTP.SOCKSProxy(@proxy.addr, @proxy.port).start(uri.hostname, uri.port, use_ssl: use_ssl) do |http|
            http.request(request)
          end
        end
      else
        Net::HTTP.start(
          uri.hostname,
          uri.port,
          use_ssl: use_ssl,
          read_timeout: timeout,
          open_timeout: timeout
        ) do |http|
          http.request(request)
        end
      end
    end
  end
end
