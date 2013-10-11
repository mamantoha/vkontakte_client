module Vkontakte
  class AskForCredentials
    attr_reader :email, :password

    def initialize
      ask_for_credentials
    end

    private

    def ask_for_credentials
      puts "Enter your credentials."

      print "Email: "
      @email = ask

      print "Password (typing will be hidden): "
      @password = ask_for_password

      nil
    end

    def ask
      $stdin.gets.to_s.strip
    end

    def ask_for_password
      echo_off
        password = ask
        puts
      echo_on

      return password
    end

    def echo_off
      with_tty do
        system "stty -echo"
      end
    end

    def echo_on
      with_tty do
        system "stty echo"
      end
    end

    def with_tty(&block)
      return unless $stdin.isatty
      yield
    end
  end
end
