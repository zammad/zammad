# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    class ExternalDataSourceFieldSort < BaseSort
      include CanApplyAdvancedSorting

      data_type 'autocompletion_ajax_external_data_source'

      def calculate_sorting
        { order: "#{meta_value_name}->>'value' #{input[:direction]}" }
      end

      private

      def meta_value_name
        "#{object.quoted_table_name}.#{object.connection.quote_column_name(column)}"
      end
    end
  end
end
