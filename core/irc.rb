require 'socket'

require_relative 'logger'

module Dinobot
  module Core
    class IRC
      def initialize(server, port, nick, pass=nil)
        @server = server
        @port = port
        @nick = nick
        @pass = pass

        @socket = nil
        @logger = Dinobot::Core::Logger.instance
      end

      def connect
        @logger.info "Connecting to #{@server}:#{@port}."

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

        @logger.in str.inspect

        str
      end

      def puts(str)
        @logger.out str.inspect

        @socket.puts str
      end

      def pong(message)
        puts "PONG #{message}"
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

      def quit(message)
        puts "QUIT :#{message}"
      end
    end
  end
end
