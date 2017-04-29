# frozen_string_literal: true

module Vkontakte
  class API
    # An exception raised by `Vkontakte::API` when given a response with an error
    class Error < StandardError
      attr_reader :method_name, :error_code, :error_msg, :params

      def initialize(method_name, error_code, error_msg, params)
        @method_name = method_name
        @error_code  = error_code.to_i
        @error_msg   = error_msg
        @params      = params
      end

      # A full description of the error
      def message
        message = "VKontakte returned an error #{@error_code}: '#{@error_msg}'"
        message << " after calling method '#{@method_name}'"
        message << " with parameters #{@params.inspect}"
      end
    end
  end
end
