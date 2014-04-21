require_relative 'base'
require_relative '../core/store'

module Dinobot
  module Module
    class Admin < Base
      def initialize(bot)
        super

        @store = Dinobot::Core::Store.new('data/admin')

        @commands << :join << :part << :quit << :load << :unload
        @commands << :listadmins << :listmodules << :listchannels

        @admins = @store.data[:admins]
        @admins ||= Array.new
      end

      def add(user)
        @admins << user unless @admins.include?(user)

        @store.data[:admins] = @admins
        @store.save
      end

      def remove(user)
        @admins.delete(user)

        @store.data[:admins] = @admins
        @store.save
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

      def quit(user, channel, argument)
        return unless is_admin?(user)

        [[:quit, argument ? argument.strip : 'Quitting.']]
      end

      def load(user, channel, argument)
        return unless is_admin?(user)

        argument.split.each do |x|
          @bot.load_module x.intern
        end

        nil
      end

      def unload(user, channel, argument)
        return unless is_admin?(user)

        argument.split.each do |x|
          @bot.unload_module x.intern
        end

        nil
      end

      def listadmins(user, channel, argument)
        return unless is_admin?(user)

        [[:say, channel, @admins.join(' ')]]
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
end
