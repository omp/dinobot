require_relative 'base'

module Dinobot
  module Module
    class Test < Base
      def initialize(bot)
        super

        @commands << :echo << :ping << :x3 << :fooify
        @commands << :error << :timeout << :wrongreturn << :invalidmethods
      end

      def echo(user, channel, argument)
        [[:say, channel, argument]]
      end

      def ping(user, channel, argument)
        [[:say, channel, 'pong']]
      end

      def x3(user, channel, argument)
        [[:say, channel, argument]] * 3
      end

      def fooify(user, channel, argument)
        [[:say, channel, 'foo' + argument]]
      end

      def error(user, channel, argument)
        x
      end

      def timeout(user, channel, argument)
        sleep 60
      end

      def wrongreturn(user, channel, argument)
        0
      end

      def invalidmethods(user, channel, argument)
        [[:say, channel]]
      end
    end
  end
end
