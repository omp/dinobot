require 'pstore'

module Dinobot
  module Core
    class Store
      attr_accessor :data

      def initialize(file)
        Dir.mkdir(File.dirname(file)) unless Dir.exist?(File.dirname(file))
        @store = PStore.new(file, true)

        read

        @data ||= Hash.new
      end

      def [](key)
        @data[key]
      end

      def []=(key, value)
        @data[key] = value
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
