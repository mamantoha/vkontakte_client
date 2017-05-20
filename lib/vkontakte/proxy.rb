# frozen_string_literal: true

module Vkontakte
  class Proxy # :nodoc:
    attr_reader :type, :addr, :port

    VALID_PROXY_TYPES = %i[http socks].freeze

    def initialize(type, addr, port)
      unless VALID_PROXY_TYPES.include?(type)
        raise(StandartError, "#{`type`} is an invalid proxy type. Available values: #{VALID_PROXY_TYPES.join(',')}")
      end

      @type = type
      @addr = addr
      @port = port
    end

    VALID_PROXY_TYPES.each do |type|
      define_method(:"#{type}?") do
        @type == type
      end
    end
  end
end
