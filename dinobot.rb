require 'socket'

module Dinobot
  class Bot
    def initialize(server, port, nick, pass=nil, &block)
      @server = server
      @port = port
      @nick = nick
      @pass = pass

      @trigger = '!'

      @socket = nil
      @modules = Hash.new
      @channels = Array.new

      instance_eval(&block) if block_given?
    end

    def connect
      @socket = TCPSocket.new(@server, @port)

      out "PASS #{@pass}" if @pass
      out "NICK #{@nick}"
      out "USER #{@nick} 0 * :#{@nick}"

      @channels.each do |channel|
        join channel
      end
    end

    def connected?
      !(@socket.nil? || @socket.closed?)
    end

    def run
      while true
        puts "== Connecting to #{@server}:#{@port}."
        connect

        while str = @socket.gets
          str.chomp!
          puts "<< " + str.inspect

          begin
            parse_line(str)
          rescue
          end
        end

        puts "== Disconnected."
        @socket.close
      end
    end

    def parse_line(str)
      out str.sub('PING', 'PONG') if str =~ /^PING /
    end

    def out(str)
      return unless connected?

      puts ">> " + str.inspect

      @socket.puts str
    end

    def say(channel, message)
      out "PRIVMSG #{channel} :#{message}"
    end

    def join(channel)
      @channels << channel unless @channels.include?(channel)

      out "JOIN #{channel}"
    end

    def part(channel)
      @channels.delete(channel)

      out "PART #{channel}"
    end
  end
end
