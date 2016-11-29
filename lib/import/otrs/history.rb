# rubocop:disable Style/ClassVars
module Import
  module OTRS
    class History

      def initialize(history)
        init_callback(history)
        ensure_history_attribute
        add
      end

      def init_callback(_)
        raise 'No init callback defined for this history!'
      end

      private

      def add
        ::History.add(@history_attributes)
      end

      # make sure that no other thread is importing just the same
      # history attribute which causes a ActiveRecord::RecordNotUnique
      # exception we (currently) can't handle otherwise
      def ensure_history_attribute
        history_attribute = @history_attributes[:history_attribute]
        return if !history_attribute
        @@created_history_attributes ||= {}
        return if @@created_history_attributes[history_attribute]
        @@created_history_attributes[history_attribute] = true
        ::History.attribute_lookup(history_attribute)
      end
    end
  end
end
