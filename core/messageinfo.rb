module Dinobot
  module Core
    class MessageInfo
      attr_accessor :user, :channel, :message, :response

      def initialize(user, channel, message)
        @user = user
        @channel = channel
        @message = message
        @response = []
      end

      def respond(arr)
        raise "response not array -- #{arr}" unless arr.is_a?(Array)

        case arr.first
        when :say
          raise "wrong number of arguments -- #{arr}" unless arr.length == 3
        when :join, :part, :quit
          raise "wrong number of arguments -- #{arr}" unless arr.length == 2
        else
          raise "unknown method name -- #{arr}"
        end

        @response << arr
      end
    end
  end
end
