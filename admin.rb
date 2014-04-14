require_relative 'module'

module Dinobot
  class Admin < Module
    def initialize
      super

      @commands << :join << :part << :listadmins << :load << :unload

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

    def listadmins(user, channel, argument)
      [[:say, channel, @admins.join(' ')]] if is_admin?(user)
    end

    def load(user, channel, argument)
      argument.split.map do |x|
        [:load_module, x.intern]
      end
    end

    def unload(user, channel, argument)
      argument.split.map do |x|
        [:unload_module, x.intern]
      end
    end
  end
end
