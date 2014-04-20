module Dinobot
  module Core
    class Logger
      @@instance = nil
      @@mutex = Mutex.new

      def in(*lines)
        str = lines.join("\n")

        puts str.gsub(/^/, "\e[32m<<\e[0m ")
      end

      def out(*lines)
        str = lines.join("\n")

        puts str.gsub(/^/, "\e[36m>>\e[0m ")
      end

      def error(*lines)
        str = lines.join("\n")

        puts str.gsub(/^/, "\e[31m!!\e[0m ")
      end

      def info(*lines)
        str = lines.join("\n")

        puts str.gsub(/^/, "\e[33m==\e[0m ")
      end

      def indent(*lines)
        str = lines.join("\n")

        puts str.gsub(/^/, '   ')
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
