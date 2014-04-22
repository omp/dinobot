require_relative 'store'

module Dinobot
  module Core
    class Aliaser
      attr_accessor :data

      @@instance = nil
      @@mutex = Mutex.new

      def initialize
        @store = Dinobot::Core::Store.new('aliaser.db')
        @data = @store.data
      end

      def add(from, to, channel=:global)
        @data[channel] = Hash.new unless @data.key?(channel)
        @data[channel][from] = to

        save
      end

      def remove(from, channel=:global)
        return unless data.key?(channel)

        @data[channel].delete(from)
        @data.delete(channel) if @data[channel].empty?

        save
      end

      def aliases
        @data.dup
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
