module Dinobot
  class Module
    attr_accessor :commands

    def initialize(bot)
      @bot = bot

      @commands = [:commands]
    end

    def call(user, channel, message)
      command, argument = message.split(' ', 3)[1..2]

      if @commands.include?(command.intern)
        send(command, user, channel, argument)
      end
    end

    def commands(user, channel, argument)
      [[:say, channel, "Commands: #{@commands.sort.join(' ')}"]]
    end
  end
end
