module Dinobot
  module Module
    class Base
      attr_accessor :commands

      def initialize(bot)
        @bot = bot

        @commands = [:commands]
      end

      def call(m, command)
        command, args = command.split(' ', 3)[1..2]
        args ||= ''

        return unless @commands.map { |x| x.to_s }.include?(command)

        send(command, m, args)
      end

      def commands(m, args)
        m.response << [:say, m.channel,
          "Commands: #{@commands.sort.join(' ')}"]
      end
    end
  end
end
