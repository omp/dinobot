require_relative 'module'

module Dinobot
  class Admin < Module
    def initialize
      super

      @commands << :join << :part

      @admins = Array.new
    end

    def add(user)
      @admins << user unless @admins.include?(user)
    end

    def remove(user)
      @admins.delete(user)
    end

    def is_admin?(user)
      # FIXME: Using hostname for testing purposes. Need better solution.
      @admins.include?(user.sub(/.+@/, ''))
    end

    def join(user, channel, argument)
      [[:join, argument]] if is_admin?(user)
    end

    def part(user, channel, argument)
      [[:part, argument]] if is_admin?(user)
    end
  end
end
