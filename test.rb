require_relative 'module'

module Dinobot
  class Test < Module
    def initialize
      super

      @commands << :echo << :error << :timeout << :x3 << :wrongreturn << :fooify
    end

    def echo(user, channel, argument)
      [[:say, channel, argument]]
    end

    def error(user, channel, argument)
      x
    end

    def timeout(user, channel, argument)
      sleep 60
    end

    def x3(user, channel, argument)
      [[:say, channel, argument]] * 3
    end

    def wrongreturn(user, channel, argument)
      0
    end

    def fooify(user, channel, argument)
      [[:say, channel, 'foo' + argument]]
    end
  end
end
