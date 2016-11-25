module Import
  module OTRS
    class History

      def initialize(history)
        init_callback(history)
        add
      end

      def init_callback(_)
        raise 'No init callback defined for this history!'
      end

      private

      def add
        ::History.add(@history_attributes)
      end
    end
  end
end
