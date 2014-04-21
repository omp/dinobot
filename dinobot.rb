require 'timeout'

require_relative 'core/config'
require_relative 'core/irc'
require_relative 'core/logger'
require_relative 'core/messageinfo'

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
        process_in_new_thread(str)
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

    def process_in_new_thread(str)
      Thread.new do
        begin
          Timeout.timeout(30) do
            process_line(str.chomp)
          end
        rescue => e
          @logger.error "Error parsing line. (#{e})"
          @logger.indent *e.backtrace
        end
      end
    end

    def process_line(str)
      @irc.pong str[5..-1] if str =~ /\APING /

      if str =~ /(\S+) PRIVMSG (\S+) :(.*)/
        user, channel, message = str.scan(/(\S+) PRIVMSG (\S+) :(.*)/).first
        m = Dinobot::Core::MessageInfo.new(user, channel, message)

        return unless message =~ /\A#{Regexp.escape(@config.data[:trigger][:global])}/
        command = message.sub(/\A#{Regexp.escape(@config.data[:trigger][:global])}/, '')

        exec_command(m, command)

        unless m.response.empty?
          ensure_valid_response(m.response)
          process_response(m.response)
        end
      end
    end

    def exec_command(m, command)
      command, remainder = command.split(' | ', 2)
      mod = command.scan(/\A\S+/).first.downcase

      return unless @modules.keys.map { |x| x.to_s }.include?(mod)
      mod = mod.intern

      if m.response.empty?
        m.response = @modules[mod].call(m.user, m.channel, command)
      else
        ensure_valid_response(m.response)
        response = []

        m.response.each do |x|
          if x.first == :say
            tmp = @modules[mod].call(m.user, x[1], "#{command} #{x[2]}")
            ensure_valid_response(tmp)
            response.concat(tmp)
          else
            response << x
          end
        end

        m.response = response
      end

      exec_command(m, remainder) if remainder
    end

    def process_response(response)
      response.each do |x|
        @logger.info "Executing method: #{x.inspect}" if @config.data[:debug]
        send(*x)
      end
    end

    def ensure_valid_response(response)
      raise "method list not array -- #{response}" unless response.is_a?(Array)

      response.each do |x|
        raise "method not array -- #{x}" unless x.is_a?(Array)

        case x.first
        when :say
          raise "wrong number of arguments -- #{x}" unless x.length == 3
        when :join, :part, :quit
          raise "wrong number of arguments -- #{x}" unless x.length == 2
        else
          raise "unknown method name -- #{x}"
        end
      end
    end
  end
end
