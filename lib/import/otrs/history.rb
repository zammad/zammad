# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# rubocop:disable Style/ClassVars
module Import
  module OTRS
    class History
      include Import::Helper

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
        reset_primary_key_sequence('histories')
      end

      # make sure that no other thread is importing just the same
      # history attribute which causes a ActiveRecord::RecordNotUnique
      # exception we (currently) can't handle otherwise
      def ensure_history_attribute
        history_attribute = @history_attributes[:history_attribute]
        return if !history_attribute
        return if history_attribute_exists?(history_attribute)

        @@created_history_attributes[history_attribute] = true
        ::History.attribute_lookup(history_attribute)
      end

      def history_attribute_exists?(name)
        @@created_history_attributes ||= {}
        return false if !@@created_history_attributes[name]

        # make sure the history attribute is added before we
        # we perform further import
        # otherwise the following import logic (add) will
        # try to add the history attribute, too
        sleep 1 until ::History::Attribute.exists?(name: name)
        true
      end
    end
  end
end
