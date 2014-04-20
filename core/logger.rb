module Dinobot
  module Core
    class Logger
      @@instance = nil
      @@mutex = Mutex.new

      def in(*lines)
        pout("\e[32m<<\e[0m ", *lines)
      end

      def out(*lines)
        pout("\e[36m>>\e[0m ", *lines)
      end

      def info(*lines)
        pout("\e[33m==\e[0m ", *lines)
      end

      def error(*lines)
        pout("\e[31m!!\e[0m ", *lines)
      end

      def indent(*lines)
        pout('   ', *lines)
      end

      private

      def pout(prefix, *lines)
        puts lines.join("\n").gsub(/^/, prefix)
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
