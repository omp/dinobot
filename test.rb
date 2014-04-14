require_relative 'module'

module Dinobot
  class Test < Module
    def initialize
      super

      @commands << :echo << :error << :timeout
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
  end
end
