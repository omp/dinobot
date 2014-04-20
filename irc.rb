require 'socket'

module Dinobot
  class IRC
    def initialize(server, port, nick, pass=nil)
      @server = server
      @port = port
      @nick = nick
      @pass = pass

      @socket = nil
    end

    def connect
      log :info, "Connecting to #{@server}:#{@port}."

      @socket = TCPSocket.new(@server, @port)

      puts "PASS #{@pass}" if @pass
      puts "NICK #{@nick}"
      puts "USER #{@nick} 0 * :#{@nick}"
    end

    def disconnect
      @socket.close
    end

    def connected?
      !(@socket.nil? || @socket.closed?)
    end

    def gets
      str = @socket.gets

      log :in, str.inspect

      str
    end

    def puts(str)
      log :out, str.inspect

      @socket.puts str
    end

    def join(channel)
      puts "JOIN #{channel}"
    end

    def part(channel)
      puts "PART #{channel}"
    end

    def privmsg(channel, message)
      puts "PRIVMSG #{channel} :#{message}"
    end

    def pong(message)
      puts "PONG #{message}"
    end

    private

    def log(type, *lines)
      str = lines.join("\n")

      case type
      when :in
        prefix = "\e[32m<<\e[0m "
      when :out
        prefix = "\e[36m>>\e[0m "
      when :error
        prefix = "\e[31m!!\e[0m "
      when :info
        prefix = "\e[33m==\e[0m "
      when :indent
        prefix = '   '
      else
        raise "unknown type specified -- #{type}"
      end

      Kernel.puts str.gsub(/^/, prefix)
    end
  end
end
