require 'timeout'

require_relative 'core/aliaser'
require_relative 'core/config'
require_relative 'core/irc'
require_relative 'core/logger'
require_relative 'core/messageinfo'
require_relative 'core/store'

module Dinobot
  class Bot
    attr_reader :server, :port, :nick, :pass, :modules, :channels

    def initialize(server, port, nick, pass=nil, &block)
      @server = server
      @port = port
      @nick = nick
      @pass = pass

      @modules = Hash.new
      @channels = Array.new

      @irc = Dinobot::Core::IRC.new(@server, @port, @nick, @pass)

      @aliaser = Dinobot::Core::Aliaser.instance
      @config = Dinobot::Core::Config.instance
      @logger = Dinobot::Core::Logger.instance

      instance_eval(&block) if block_given?
    end

    def run
      @irc.connect unless @irc.connected?

      @channels.each do |channel|
        @irc.join(channel)
      end

      while line = @irc.gets
        process_line(line)
      end

      @irc.disconnect
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

      begin
        raise 'module not loaded' unless @modules.key?(mod)

        @modules.delete(mod)
        m = Dinobot::Module.send(:remove_const,
          Dinobot::Module.constants.find { |x| x.downcase == mod })

        @logger.info "Unloaded module: #{mod} (#{m})"
      rescue => e
        @logger.error "Failed to unload module: #{mod} (#{e})"
      end
    end

    def add_alias(from, to)
      @aliaser.add(from, to)
    end

    def remove_alias(from)
      @aliaser.remove(from)
    end

    private

    def process_line(line)
      Thread.new do
        begin
          Timeout.timeout(30) do
            process_line_thread(line.chomp)
          end
        rescue => e
          @logger.error "Error parsing line. (#{e})"
          @logger.indent *e.backtrace
        end
      end
    end

    def process_line_thread(line)
      @irc.pong(line[5..-1]) if line =~ /\APING /

      if line =~ /\A(\S+) PRIVMSG (\S+) :(.*)/
        user, channel, message = line.scan(/\A(\S+) PRIVMSG (\S+) :(.*)/).first
        m = Dinobot::Core::MessageInfo.new(user, channel, message)

        return unless message =~
          /\A#{Regexp.escape(@config[:trigger][:global])}/

        command = message
          .sub(/\A#{Regexp.escape(@config[:trigger][:global])}/, '')

        exec_command(m, command)
        process_response(m) if m.response?
      end
    end

    def exec_command(m, command)
      # FIXME: Improve and add debug output.
      if @aliaser.aliases.key?(:global)
        @aliaser.aliases[:global].each do |k, v|
          command.sub!(/\A#{Regexp.escape(k)}\b/, v)
        end
      end

      command, remainder = command.split(' | ', 2)
      mod = command.scan(/\A\S+/).first.downcase

      return unless @modules.keys.map { |x| x.to_s }.include?(mod)
      mod = mod.intern

      if m.response?
        tmp = m.response
        m.response = []

        tmp.each do |x|
          if x.first == :say
            # FIXME: Retain original channel value?
            @modules[mod].call(m, "#{command} #{x[2]}")
          else
            m.respond x
          end
        end
      else
        @modules[mod].call(m, command)
      end

      exec_command(m, remainder) if remainder
    end

    def process_response(m)
      m.response.each do |x|
        @logger.info "Executing method: #{x.inspect}" if @config[:debug]
        send(*x)
      end
    end
  end
end
