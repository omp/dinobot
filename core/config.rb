require_relative 'store'

module Dinobot
  module Core
    class Config
      attr_accessor :data

      @@instance = nil
      @@mutex = Mutex.new

      def initialize
        @store = Dinobot::Core::Store.new('config')
        @data = @store.data

        if @data.empty?
          @data[:debug] = false
          @data[:trigger] = {global: '!'}

          save
        end
      end

      def save
        @store.save
      end

      class << self
        def instance
          return @@instance if @@instance

          @@mutex.synchronize do
            @@instance ||= new
          end
        end
      end

      private_class_method :allocate, :new
    end
  end
end
