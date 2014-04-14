module Dinobot
  class Module
    attr_accessor :commands

    def initialize
      @commands = [:commands]
    end

    def call(user, channel, message)
      message = message.split(' ', 2).last
      command = message.split.first

      if @commands.include?(command.intern)
        send(command, user, channel, message)
      end
    end

    def commands(user, channel, message)
      [[:say, channel, "Commands: #{@commands.sort.join(' ')}"]]
    end
  end
end
