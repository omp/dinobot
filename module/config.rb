require_relative 'base'
require_relative '../core/config'

module Dinobot
  module Module
    class Config < Base
      def initialize(bot)
        super

        @config = Dinobot::Core::Config.instance

        @commands << :get << :set
      end

      def get(user, channel, argument)
        return unless @bot.modules[:admin].is_admin?(user)

        case argument
        when 'trigger'
          [[:say, channel, @config.data[:trigger][:global]]]
        when 'debug'
          [[:say, channel, @config.data[:debug].to_s]]
        else
          nil
        end
      end

      def set(user, channel, argument)
        return unless @bot.modules[:admin].is_admin?(user)

        key, val = argument.split(' ')
        return unless val

        case key
        when 'trigger'
          @config.data[:trigger][:global] = val
          @config.save
        when 'debug'
          case val
          when 'true'
            @config.data[:debug] = true
            @config.save
          when 'false'
            @config.data[:debug] = false
            @config.save
          end
        end

        nil
      end
    end
  end
end
