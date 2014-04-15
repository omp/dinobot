require 'socket'
require 'timeout'

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

        Thread.new do
          begin
            Timeout.timeout(30) do
              parse_line(str)
            end
          rescue => e
            puts "!! Error parsing line. (#{e})"
            puts e.backtrace
          end
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

        methods = parse_command(user, channel, message)

        run_methods(methods) if methods.is_a?(Array)
      end
    end

    def parse_command(user, channel, command, prev=nil)
      command, remainder = command.split(' | ', 2)
      mod = command.scan(/\A\S+/).first.downcase.intern

      if prev.nil?
        methods = @modules[mod].call(user, channel, command)
      else
        methods = []

        prev.each do |p|
          if p.first == :say
            m = @modules[mod].call(user, p[1], "#{command} #{p[2]}")

            methods.concat(m) if m.is_a?(Array)
          else
            methods << p
          end
        end
      end

      remainder ? parse_command(user, channel, remainder, methods) : methods
    end

    def run_methods(methods)
      methods.each do |method|
        puts "== Executing method: #{method.inspect}"

        case method.first
        when :say
          send(*method) if method.length == 3
        when :join, :part
          send(*method) if method.length == 2
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
        @modules[mod] = m.new(self)

        puts "== Loaded module: #{mod} (#{m})"
      rescue LoadError, StandardError => e
        puts "!! Failed to load module: #{mod} (#{e})"
      end
    end

    def unload_module(mod)
      mod = mod.downcase.intern
      puts "== Unloading module: #{mod}"

      unless @modules.has_key?(mod)
        puts "!! Failed to unload module: #{mod} (module not loaded)"
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
