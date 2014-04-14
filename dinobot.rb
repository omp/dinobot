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

      if str =~ /(\S+) PRIVMSG (\S+) :(.*)/
        user, channel, message = str.scan(/(\S+) PRIVMSG (\S+) :(.*)/).first

        if message =~ /^#{Regexp.escape(@trigger)}/
          message.sub!(@trigger, '')

          mod = message.split.first.downcase.intern

          if @modules.has_key?(mod)
            exec_commands(@modules[mod].call(user, channel, message))
          end
        end
      end
    end

    def exec_commands(commands)
      commands.each do |command|
        case command.first
        when :say
          send(*command) if command.length == 3
        when :join, :part
          send(*command) if command.length == 2
        end
      end
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

    def load_module(mod)
      file = Dir.entries(File.dirname(__FILE__)).find { |x| x == mod.to_s.downcase + ".rb" }

      if file
        puts "== Loading #{mod}."

        load file
        @modules[mod.downcase] = eval("Dinobot::#{mod}").new
      end
    end
  end
end
