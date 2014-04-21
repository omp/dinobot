require 'timeout'

require_relative 'core/config'
require_relative 'core/irc'
require_relative 'core/logger'

module Dinobot
  class Bot
    attr_accessor :trigger
    attr_reader :server, :port, :nick, :pass, :modules, :channels

    def initialize(server, port, nick, pass=nil, &block)
      @server = server
      @port = port
      @nick = nick
      @pass = pass

      @irc = Dinobot::Core::IRC.new(@server, @port, @nick, @pass)
      @config = Dinobot::Core::Config.instance
      @logger = Dinobot::Core::Logger.instance

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
      @logger.info 'Disconnected.'
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

    def quit(message)
      @irc.quit(message)
    end

    def load_module(mod)
      mod = mod.downcase.intern
      @logger.info "Loading module: #{mod}"

      begin
        load "module/#{mod}.rb"

        m = Dinobot::Module.const_get(
          Dinobot::Module.constants.find { |x| x.downcase == mod })
        @modules[mod] = m.new(self)

        @logger.info "Loaded module: #{mod} (#{m})"
      rescue LoadError, StandardError => e
        @logger.error "Failed to load module: #{mod} (#{e})"
      end
    end

    def unload_module(mod)
      mod = mod.downcase.intern
      @logger.info "Unloading module: #{mod}"

      begin
        raise 'module not loaded' unless @modules.has_key?(mod)

        @modules.delete(mod)
        m = Dinobot::Module.send(:remove_const,
          Dinobot::Module.constants.find { |x| x.downcase == mod })

        @logger.info "Unloaded module: #{mod} (#{m})"
      rescue => e
        @logger.error "Failed to unload module: #{mod} (#{e})"
      end
    end

    private

    def parse_in_new_thread(str)
      Thread.new do
        begin
          Timeout.timeout(30) do
            parse_line(str.chomp)
          end
        rescue => e
          @logger.error "Error parsing line. (#{e})"
          @logger.indent *e.backtrace
        end
      end
    end

    def parse_line(str)
      @irc.pong str.sub(/\APING /, '') if str =~ /\APING /

      if str =~ /(\S+) PRIVMSG (\S+) :(.*)/
        user, channel, message = str.scan(/(\S+) PRIVMSG (\S+) :(.*)/).first

        return unless message.sub!(/^#{Regexp.escape(@config.data[:trigger][:global])}/, '')

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
        @logger.info "Executing method: #{m.inspect}" if @config.data[:debug]
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
        when :join, :part, :quit
          raise "wrong number of arguments -- #{m}" unless m.length == 2
        else
          raise "unknown method name -- #{m}"
        end
      end
    end
  end
end
