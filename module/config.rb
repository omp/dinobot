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
          m.respond [:say, m.channel, @config[:trigger][:global]]
        when 'debug'
          m.respond [:say, m.channel, @config[:debug].to_s]
        end
      end

      def set(m, args)
        return unless @bot.modules[:admin].is_admin?(m.user)

        key, val = args.split(' ')
        return unless val

        case key
        when 'trigger'
          @config[:trigger][:global] = val
          @config.save
        when 'debug'
          case val
          when 'true'
            @config[:debug] = true
            @config.save
          when 'false'
            @config[:debug] = false
            @config.save
          end
        end
      end
    end
  end
end
