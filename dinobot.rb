require 'socket'

module Dinobot
  class Bot
    attr_accessor :trigger
    attr_reader :server, :port, :nick, :pass, :modules, :channels

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
      puts "== Connecting to #{@server}:#{@port}."
      connect

      while str = @socket.gets
        str.chomp!
        puts "<< #{str.inspect}"

        begin
          parse_line(str)
        rescue => e
          puts "== Error parsing line. (#{e})"
        end
      end

      puts '== Disconnected.'
      @socket.close
    end

    def parse_line(str)
      out str.sub('PING', 'PONG') if str =~ /^PING /

      if str =~ /(\S+) PRIVMSG (\S+) :(.*)/
        user, channel, message = str.scan(/(\S+) PRIVMSG (\S+) :(.*)/).first

        return unless message =~ /^#{Regexp.escape(@trigger)}/

        message.sub!(@trigger, '')

        mod = message.split.first.downcase.intern

        if @modules.has_key?(mod)
          commands = @modules[mod].call(user, channel, message)

          exec_commands(commands) unless commands.nil?
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

      puts ">> #{str.inspect}"

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
      mod = mod.downcase.intern
      puts "== Loading module: #{mod}"

      begin
        load "#{mod}.rb"

        m = Dinobot.const_get(Dinobot.constants.find { |x| x.downcase == mod })
        @modules[mod] = m.new

        puts "== Loaded module: #{mod} (#{m})"
      rescue LoadError, StandardError => e
        puts "== Failed to load module: #{mod} (#{e})"
      end
    end

    def unload_module(mod)
      mod = mod.downcase.intern
      puts "== Unloading module: #{mod}"

      unless @modules.has_key?(mod)
        puts "== Failed to unload module: #{mod} (module not loaded)"
        return
      end

      @modules.delete(mod)

      Dinobot.send(
        :remove_const,
        Dinobot.constants.find { |x| x.downcase == mod }
      )
    end
  end
end
