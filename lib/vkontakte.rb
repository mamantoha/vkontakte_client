# frozen_string_literal: true

require 'json'
require 'net/http'
require 'mechanize'
require 'socksify'
require 'socksify_mechanize'
require 'pry'

require 'vkontakte/version'
require 'vkontakte/client'
require 'vkontakte/api'
require 'vkontakte/api_error'
require 'vkontakte/proxy'
require 'vkontakte/ask_for_credentials'

module Vkontakte
  API_VERSION = '5.101'
end
