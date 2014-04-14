require_relative 'module'

module Dinobot
  class Echo < Module
    def initialize
      super

      @commands << :echo
    end

    def echo(user, channel, message)
      [[:say, channel, message]]
    end
  end
end
