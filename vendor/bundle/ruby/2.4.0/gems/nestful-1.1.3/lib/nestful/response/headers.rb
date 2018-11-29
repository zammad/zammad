module Nestful
  class Response #:nodoc:
    class Headers
      include ::Net::HTTPHeader

      def initialize(header = {})
        @header = header
      end

      def ==(other)
        @header == other
      end

      def inspect
        @header.inspect
      end

      def method_missing(name, *args, &block)
        if @header.respond_to?(name)
          @header.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to?(method)
        super || @header.respond_to?(method)
      end
    end
  end
end
