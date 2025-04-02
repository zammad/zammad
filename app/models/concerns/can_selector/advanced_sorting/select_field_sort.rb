# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    class SelectFieldSort < BaseSelectFieldSort
      data_type 'select'

      private

      def fetch_names_and_ids
        return historical_options.map { |k, v| [k, v] } if !custom_sort?

        object_manager_attribute.data_option[:options].map { |h| [h['value'], h['name']] }
      end

      def sort(names_and_ids)
        locale_object = Locale.find_by(locale:)

        if !locale_object && !custom_sort?
          names_and_ids.sort_by!(&:second)
          return names_and_ids
        end

        return names_and_ids if custom_sort?

        comparator = TwitterCldr::Collation::Collator.new(locale_object.cldr_language_code)

        if translate?
          names_and_ids.sort! { |a, b| comparator.compare(a.third, b.third) }
        else
          names_and_ids.sort! { |a, b| comparator.compare(a.second, b.second) }
        end

        names_and_ids
      end

      def custom_sort?
        object_manager_attribute.data_option[:customsort].present? && object_manager_attribute.data_option[:customsort] == 'on'
      end
    end
  end
end
