require_relative 'module'

module Dinobot
  class Admin < Module
    def initialize(bot)
      super

      @commands << :join << :part << :load << :unload
      @commands << :listadmins << :listmodules << :listchannels

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
      return unless is_admin?(user)

      [[:join, argument.strip]]
    end

    def part(user, channel, argument)
      return unless is_admin?(user)

      [[:part, argument.strip]]
    end

    def listadmins(user, channel, argument)
      return unless is_admin?(user)

      [[:say, channel, @admins.join(' ')]]
    end

    def load(user, channel, argument)
      return unless is_admin?(user)

      argument.split.each do |x|
        @bot.load_module x.intern
      end
    end

    def unload(user, channel, argument)
      return unless is_admin?(user)

      argument.split.each do |x|
        @bot.unload_module x.intern
      end
    end

    def listmodules(user, channel, argument)
      return unless is_admin?(user)

      [[:say, channel, "Modules: #{@bot.modules.keys.sort.join(' ')}"]]
    end

    def listchannels(user, channel, argument)
      return unless is_admin?(user)

      [[:say, channel, "Channels: #{@bot.channels.sort.join(' ')}"]]
    end
  end
end
