# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    class TranslatedRelationSort < BaseSort
      def self.applicable?(input, locale, object)
        return false if locale.blank?

        attr = ObjectManager::Attribute.get(object: object.name, name: column_name(input, object))
        return false if attr.nil?

        attr.data_option[:relation].present? && attr.data_option[:translate]
      end

      def calculate_sorting
        command = case ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
                  when 'postgresql'
                    "array_position(ARRAY[#{cached_sorted_ids}], #{adjusted_column})"
                  when 'mysql2'
                    "FIELD(#{adjusted_column}, #{cached_sorted_ids})"
                  end

        {
          order:  "#{meta_value_name} #{input[:direction]}",
          select: "#{command} as #{meta_value_name}",
        }
      end

      private

      def cached_sorted_ids
        Rails.cache.fetch(sorted_ids_cache_key) { calculate_sorted_ids }
      end

      def sorted_ids_cache_key
        "translated-relations-sort-#{locale}-#{assoc.klass.all.cache_key_with_version}-#{Translation.all.cache_key_with_version}"
      end

      def calculate_sorted_ids
        names_and_ids = assoc.klass.pluck(:id, :name)

        translations = Translation.translate_all locale, *names_and_ids.map(&:second)

        names_and_ids.each do |name_and_id|
          name_and_id << translations[name_and_id.second]
        end

        locale_object = Locale.find_by(locale:)

        if locale_object
          comparator = TwitterCldr::Collation::Collator.new(locale_object.cldr_language_code)

          names_and_ids.sort! { |a, b| comparator.compare(a.third, b.third) }
        else
          names_and_ids.sort_by!(&:third)
        end

        names_and_ids.map(&:first).join(',')
      end

      def meta_value_name
        object.connection.quote_column_name("_advanced_sorting_#{object.name}_#{column}")
      end

      def adjusted_column
        raw_selectors_quoted_column(assoc.foreign_key)
      end

      def assoc
        @assoc ||= object.reflect_on_association(column.delete_suffix('_id'))
      end
    end
  end
end
