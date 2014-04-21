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

      def join(m, args)
        return unless is_admin?(m.user)

        m.response << [:join, args.strip]
      end

      def part(m, args)
        return unless is_admin?(m.user)

        m.response << [:part, args.strip]
      end

      def quit(m, args)
        return unless is_admin?(m.user)

        m.response << [:quit, args ? args.strip : 'Quitting.']
      end

      def load(m, args)
        return unless is_admin?(m.user)

        args.split.each do |x|
          @bot.load_module x.intern
        end
      end

      def unload(m, args)
        return unless is_admin?(m.user)

        args.split.each do |x|
          @bot.unload_module x.intern
        end
      end

      def listadmins(m, args)
        return unless is_admin?(m.user)

        m.response << [:say, m.channel, "Admins: #{@admins.join(' ')}"]
      end

      def listmodules(m, args)
        return unless is_admin?(m.user)

        m.response << [:say, m.channel,
          "Modules: #{@bot.modules.keys.sort.join(' ')}"]
      end

      def listchannels(m, args)
        return unless is_admin?(m.user)

        m.response << [:say, m.channel,
          "Channels: #{@bot.channels.sort.join(' ')}"]
      end
    end
  end
end
