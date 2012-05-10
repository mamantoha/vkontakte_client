# -*- encoding: utf-8 -*-

require 'oauth2'

require_relative 'vkontakte/version'

module Vkontakte
  autoload :Client, 'vkontakte/client'
  autoload :API, 'vkontakte/api'
  autoload :VkException, 'vkontakte/vkexception'
end
