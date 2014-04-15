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
      log :info, "Connecting to #{@server}:#{@port}."
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
      connect unless connected?

      while str = @socket.gets.chomp
        log :in, str.inspect

        Thread.new do
          begin
            Timeout.timeout(30) do
              parse_line(str)
            end
          rescue => e
            log :error, "Error parsing line. (#{e})"
            log :indent, *e.backtrace
          end
        end
      end

      @socket.close
      log :info, 'Disconnected.'
    end

    def out(str)
      return unless connected?

      log :out, str.inspect
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
      log :info, "Loading module: #{mod}"

      begin
        load "#{mod}.rb"

        m = Dinobot.const_get(Dinobot.constants.find { |x| x.downcase == mod })
        @modules[mod] = m.new(self)

        log :info, "Loaded module: #{mod} (#{m})"
      rescue LoadError, StandardError => e
        log :error, "Failed to load module: #{mod} (#{e})"
      end
    end

    def unload_module(mod)
      mod = mod.downcase.intern
      log :info, "Unloading module: #{mod}"

      begin
        raise 'module not loaded' unless @modules.has_key?(mod)

        @modules.delete(mod)
        m = Dinobot.send(:remove_const,
          Dinobot.constants.find { |x| x.downcase == mod })

        log :info, "Unloaded module: #{mod} (#{m})"
      rescue => e
        log :error, "Failed to unload module: #{mod} (#{e})"
      end
    end

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

      puts str.gsub(/^/, prefix)
    end

    private

    def parse_line(str)
      out str.sub('PING', 'PONG') if str =~ /^PING /

      if str =~ /(\S+) PRIVMSG (\S+) :(.*)/
        user, channel, message = str.scan(/(\S+) PRIVMSG (\S+) :(.*)/).first

        return unless message.sub!(/^#{Regexp.escape(@trigger)}/, '')

        methods = exec_command(user, channel, message)
        # TODO: Check if methods is valid list of methods.
        run_methods(methods) if methods.is_a?(Array)
      end
    end

    def exec_command(user, channel, command, prev=nil)
      command, remainder = command.split(' | ', 2)
      mod = command.scan(/\A\S+/).first.downcase

      return unless @modules.keys.map { |x| x.to_s }.include?(mod)
      mod = mod.intern

      if prev.nil?
        methods = @modules[mod].call(user, channel, command)
      else
        methods = []

        prev.each do |p|
          if p.first == :say
            m = @modules[mod].call(user, p[1], "#{command} #{p[2]}")

            # TODO: Check if m is valid list of methods.
            methods.concat(m) if m.is_a?(Array)
          else
            methods << p
          end
        end
      end

      remainder ? exec_command(user, channel, remainder, methods) : methods
    end

    def run_methods(methods)
      methods.each do |method|
        log :info, "Executing method: #{method.inspect}"

        # TODO: Raise error if unknown method name or incorrect argument count.
        case method.first
        when :say
          send(*method) if method.length == 3
        when :join, :part
          send(*method) if method.length == 2
        end
      end
    end
  end
end
