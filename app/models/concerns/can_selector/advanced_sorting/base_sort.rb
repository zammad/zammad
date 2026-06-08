# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    class BaseSort
      attr_reader :input, :locale, :object

      def initialize(input, locale, object)
        @input  = input
        @locale = locale
        @object = object
      end

      def calculate_sorting
        raise 'not implemented'
      end

      def self.applicable?(_input, _locale, _object)
        raise 'not implemented'
      end

      def self.column_name(column_or_input, object, fallback: nil)
        column = column_or_input.is_a?(Hash) ? column_or_input[:column] : column_or_input

        column_names = object.column_names

        return column if column_names.include?(column.to_s)

        return "#{column}_id" if column_names.include?("#{column}_id")

        return fallback if fallback && column_names.include?(fallback.to_s)

        Rails.logger.error "The chosen sort column is unknown ('#{column}'), falling back to 'created_at'."

        'created_at'
      end

      def column
        input[:column].to_s
      end

      def direction
        input[:direction]
      end

      def raw_selectors_quoted_column(column)
        "#{object.quoted_table_name}.#{object.connection.quote_column_name(column)}"
      end

      def collate
        locale_object = Locale.find_by(locale:)

        quoted_collation = ApplicationModel.connection.quote_column_name(locale_object.postgres_collation_name)

        "COLLATE #{quoted_collation}"
      end
    end
  end
end
