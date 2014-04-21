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
    end
  end
end
