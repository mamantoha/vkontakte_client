module Vkontakte
  class VkException < Exception
    attr_reader :vk_method, :error_code, :error_msg

    def initialize(vk_method, error_code, error_msg)
      @vk_method  = vk_method
      @error_code = error_code.to_i
      @error_msg  = error_msg
    end
  end
end
