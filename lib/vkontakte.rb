# encoding: utf-8

require 'json'
require 'net/http'

require_relative 'vkontakte/version'

module Vkontakte
  autoload :Client, 'vkontakte/client'
  autoload :API, 'vkontakte/api'
  autoload :VkException, 'vkontakte/vkexception'
  autoload :AskForCredentials, 'vkontakte/ask_for_credentials'
end
