# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    class BooleanFieldSort < BaseSelectFieldSort
      data_type 'boolean'

      private

      def sort(names_and_ids)
        locale_object = Locale.find_by(locale:)

        if !locale_object
          names_and_ids.sort_by!(&:second)
          return names_and_ids
        end

        comparator = TwitterCldr::Collation::Collator.new(locale_object.cldr_language_code)

        if translate?
          names_and_ids.sort! { |a, b| comparator.compare(a.third, b.third) }
        else
          names_and_ids.sort! { |a, b| comparator.compare(a.second, b.second) }
        end

        names_and_ids
      end

      def build_id_string(names_and_ids)
        names_and_ids.map(&:first)
      end

      def historical_options
        object_manager_attribute.data_option[:options] || {}
      end
    end
  end
end
