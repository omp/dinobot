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

      def response?
        !@response.empty?
      end
    end
  end
end
