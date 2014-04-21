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

      def get(m, args)
        return unless @bot.modules[:admin].is_admin?(m.user)

        case args
        when 'trigger'
          m.response << [:say, m.channel, @config.data[:trigger][:global]]
        when 'debug'
          m.response << [:say, m.channel, @config.data[:debug].to_s]
        end
      end

      def set(m, args)
        return unless @bot.modules[:admin].is_admin?(m.user)

        key, val = args.split(' ')
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
      end
    end
  end
end
