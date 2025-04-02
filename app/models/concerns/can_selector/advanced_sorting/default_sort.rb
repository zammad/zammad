# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    class DefaultSort < BaseSort
      def self.applicable?(_input, _locale, _object)
        true
      end

      def calculate_sorting
        if object.columns_hash[adjusted_column.to_s].type == :string
          "#{raw_selectors_quoted_column(adjusted_column)} #{collate} #{direction}"
        else
          "#{raw_selectors_quoted_column(adjusted_column)} #{direction}"
        end
      end

      private

      def adjusted_column
        self.class.column_name(column, object, fallback: 'created_at')
      end
    end
  end
end
