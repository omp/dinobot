require 'timeout'

require_relative 'irc'

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

      @irc = Dinobot::IRC.new(@server, @port, @nick, @pass)
      @modules = Hash.new
      @channels = Array.new

      instance_eval(&block) if block_given?
    end

    def run
      @irc.connect unless @irc.connected?

      @channels.each do |channel|
        @irc.join channel
      end

      while str = @irc.gets
        parse_in_new_thread(str)
      end

      @irc.disconnect
      log :info, 'Disconnected.'
    end

    def say(channel, message)
      @irc.privmsg(channel, message)
    end

    def join(channel)
      @channels << channel unless @channels.include?(channel)

      @irc.join(channel) if @irc.connected?
    end

    def part(channel)
      @channels.delete(channel)

      @irc.part(channel)
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

    def parse_in_new_thread(str)
      Thread.new do
        begin
          Timeout.timeout(30) do
            parse_line(str.chomp)
          end
        rescue => e
          log :error, "Error parsing line. (#{e})"
          log :indent, *e.backtrace
        end
      end
    end

    def parse_line(str)
      @irc.pong str.sub(/\APING /, 'PONG') if str =~ /\APING /

      if str =~ /(\S+) PRIVMSG (\S+) :(.*)/
        user, channel, message = str.scan(/(\S+) PRIVMSG (\S+) :(.*)/).first

        return unless message.sub!(/^#{Regexp.escape(@trigger)}/, '')

        if methods = exec_command(user, channel, message)
          ensure_valid_methods(methods)
          run_methods(methods)
        end
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
        ensure_valid_methods(prev)
        methods = []

        prev.each do |p|
          if p.first == :say
            m = @modules[mod].call(user, p[1], "#{command} #{p[2]}")
            ensure_valid_methods(m)
            methods.concat(m)
          else
            methods << p
          end
        end
      end

      remainder ? exec_command(user, channel, remainder, methods) : methods
    end

    def run_methods(methods)
      methods.each do |m|
        log :info, "Executing method: #{m.inspect}"
        send(*m)
      end
    end

    def ensure_valid_methods(methods)
      raise "method list not array -- #{methods}" unless methods.is_a?(Array)

      methods.each do |m|
        raise "method not array -- #{m}" unless m.is_a?(Array)

        case m.first
        when :say
          raise "wrong number of arguments -- #{m}" unless m.length == 3
        when :join, :part
          raise "wrong number of arguments -- #{m}" unless m.length == 2
        else
          raise "unknown method name -- #{m}"
        end
      end
    end
  end
end
