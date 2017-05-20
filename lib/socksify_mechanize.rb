# frozen_string_literal: true

require 'socksify'
require 'socksify/http'

# agent = Mechanize.new
# agent.agent.set_socks('localhost', 9050) #Use Tor as proxy
#
class Mechanize::HTTP::Agent
  def set_socks(addr, port)
    set_http unless @http

    class << @http
      attr_accessor :socks_addr, :socks_port

      def http_class
        Net::HTTP.SOCKSProxy(socks_addr, socks_port)
      end
    end

    @http.socks_addr = addr
    @http.socks_port = port
  end
end
