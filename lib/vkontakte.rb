# -*- encoding: utf-8 -*-

require 'digest/md5'
require 'json'
require 'mechanize'
require 'logger'
require 'httparty'

class String
  def strtr(tr)
    sorted_tr = tr.sort{|a, b| b[0] <=> a[0]}
    keys = sorted_tr.map{|k, v| k}
    values = sorted_tr.map{|k, v| v}
    r = /(#{keys.map{|i| Regexp.escape(i)}.join( ')|(' )})/
    self.gsub(r){|match| values[keys.index(match)]}
  end
end

class Hash
  # Hash#reject is like Hash#dup.delete_if
  # h = {:a => 1, :b => 2, :c => 3}
  # h.only :a, :b    # => {:a => 1, :b => 2}
  # h.except :a, :b  # => {:c => 3}
  #
  def except(*blacklist)
    self.reject{|k ,v| blacklist.include?(k)}
  end
  
  def only(*whitelist)
    self.reject{|k ,v| !whitelist.include?(k)}
  end

end


module VK

  # = Synopsis 
  #
  # == Example
  #    require 'vk'
  #    APP_ID = '1864195'
  #    email = 'user@example.com'
  #    pass = 'secret'
  #    vk = VK::DesktopAuth.new(APP_ID)
  #    vk.login!(email, pass)
  #    mid, sid, secret = vk.mid, vk.sid, vk.secret
  #    
  class DesktopAuth
    ##
    #
    attr_reader :app_id
    attr_reader :mid
    attr_reader :sid
    attr_reader :secret
    attr_reader :login

    def initialize(app_id)
      @login = false
      @app_id = app_id

      @agent = Mechanize.new{|a|
        a.user_agent_alias = 'Linux Konqueror'
        #a.log = Logger.new('vk.log')
      }

      yield self if block_given?
    end

    def login!(email, pass)
      #              1     (дозволити додатку присилати вам повідомлення)
      # friends.*    2     (доступ до друзів)
      # photos.*     4     (доступ до фотографій)
      # audio.*      8     (доступ до аудіозаписів)
      # video.*      16    (доступ до відеозаписів)
      # offers.*     32    (доступ до пропозицій)
      # questions.*  64    (доступ до запитань)
      # pages.*      128   (доступ до wiki-сторінок)
      #              256   (виводити посилання на додаток в меню зліва)
      # wall.* -     512   (публікація на стінах користувачів)
      # activity.*   1024  (оновлення статусу)
      # notes.*      2048  (доступ до заміток)
      # messages.*   4096  (доступ до повідомлень)
      # wall.*       8192  (доступ до записів на вашій стіні)

      login_url = "http://vk.com/login.php?app=#{@app_id}&layout=popup&type=browser&settings=13854"
      puts login_url
      login_page = @agent.get(login_url)

      login_form = login_page.form_with(:name => 'real_login')
      login_form.email = email
      login_form.pass = pass
      verify_page = login_form.submit

      if verify_page.uri.to_s == 'http://vk.com/login.php?act=auth_result&m=3'
        raise "No such email address has been registered or your password is incorrect."
      else
        @login = true
      end

      params_page = verify_page.forms.first.submit
      session_params = JSON::parse(/\((.*)\)/.match(params_page.body)[1])
      @mid, @sid, @secret =  session_params['mid'], session_params['sid'], session_params['secret']

      return @login

    end

    def set_proxy(host, port)
      @agent.set_proxy(host, port)
    end

  end

  # = Synopsis
  # Клас для роботи з API Вконтакте.
  #
  # Після отримання сесії взаємодія з ВКонтакте API проводиться шляхом створення HTTP-запиту (POST або GET)
  # до адреси API-сервісу http://api.vkontakte.ru або http://api.vk.com
  #
  # Опис методів API: http://vkontakte.ru/page2369282
  #
  # == Example
  #    require 'vk'
  #    APP_ID = '1864195'
  #    email = 'user@example.com'
  #    pass = 'secret'
  #
  #    vk = VK::DesktopAuth.new(APP_ID){|auth|
  #      auth.login!(email, pass)
  #    }
  #    mid, sid, secret = vk.mid, vk.sid, vk.secret
  #
  #    api = VK::API.new(APP_ID, mid, sid, secret)
  #    puts api.getProfiles({:uids => mid, :fields => 'photo_big,sex,country,city'})
  #
  class API

    include HTTParty

    base_uri 'http://api.vk.com'            # базовий URI, який використовується для всіх запитів
    default_params :v => '3.0', :format => 'JSON' # параметри по замовчуванню для рядка запиту
    format :json                                  # дозволяє отримати результат відразу розфасований в Hash
    #http_proxy 'address', 'port'                 # параметри HTTP-проксі
    #debug_output $stderr                         # вихідний потік для налагодження

    def initialize(api_id, mid, sid, secret)
      @api_id, @mid, @sid, @secret = api_id, mid, sid, secret
      self.class.default_params :api_id => api_id, :sid => sid
    end

    def method_missing(method, *args)
      vk_method = method.to_s.split('_').join('.')
      response = execute(vk_method, *args)
      if response['error']
        raise VkException, "Error in `#{vk_method}': #{response['error']['error_code']}: #{response['error']['error_msg']}"
      end

      return response['response']
    end

    private

    def execute(method, params = {})
      query = params.update({:method => method})
      sig_params = self.class.default_params.update(query)

      self.class.post('/api.php', :query => query.update(:sig => sig(sig_params)))
    end

    ####
    # Параметр sig рівний md5 від конкатенації наступних рядків:
    #   <b>mid</b> - id поточного користувача, отриманий раніше при авторизації
    #   пар <em>"parameter_name=parameter_value"</em>, розміщених у порядку зростання імені параметру(по алфавіту) за виключенням параметру <b>sid</b>
    #   секрету сесії <b>secret</b>, отриманий раніше при авторизації
    #
    def sig(params)
      sorted_params_in_string = params.except(:sid).sort {|a, b| a[0] <=> b[0]}.map {|i| "#{i[0]}=#{i[1]}" }.join
      sig_string = "#{@mid}#{sorted_params_in_string}#{@secret}"
      
      return Digest::MD5.hexdigest(sig_string)
    end
  end

  class VkException < Exception
  end

end

