require 'pstore'

module Dinobot
  module Core
    class Store
      attr_accessor :data

      def initialize(file)
        @store = PStore.new(file, true)

        read

        @data ||= {}
      end

      def read
        @store.transaction(true) do
          @data = @store[:data]
        end
      end

      def save
        @store.transaction do
          @store[:data] = @data
        end
      end
    end
  end
end
