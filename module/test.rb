require_relative 'base'

module Dinobot
  module Module
    class Test < Base
      def initialize(bot)
        super

        @commands << :echo << :ping << :x3 << :fooify
        @commands << :error << :timeout << :invalidresponse
      end

      def echo(m, args)
        m.response << [:say, m.channel, args]
      end

      def ping(m, args)
        m.response << [:say, m.channel, 'pong']
      end

      def x3(m, args)
        3.times do
          m.response << [:say, m.channel, args]
        end
      end

      def fooify(m, args)
        m.response << [:say, m.channel, "foo#{args}"]
      end

      def error(m, args)
        x
      end

      def timeout(m, args)
        sleep 60
      end

      def invalidresponse(m, args)
        m.response << [:say, m.channel]
      end
    end
  end
end
