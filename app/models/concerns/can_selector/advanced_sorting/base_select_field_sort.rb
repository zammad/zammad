# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    class BaseSelectFieldSort < BaseSort
      include CanApplyAdvancedSorting

      def calculate_sorting
        command = case ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
                  when 'postgresql'
                    column_part = cached_sorted_ids.include?("'") ? "CAST(#{adjusted_column} as TEXT)" : adjusted_column

                    "array_position(ARRAY[#{cached_sorted_ids}], #{column_part})"
                  when 'mysql2'
                    "FIELD(#{adjusted_column}, #{cached_sorted_ids})"
                  end

        {
          order:  "#{meta_value_name} #{input[:direction]}",
          select: "#{command} as #{meta_value_name}",
        }
      end

      private

      def fetch_names_and_ids
        historical_options.map { |k, v| [k, v] }
      end

      def cached_sorted_ids
        Rails.cache.fetch(sorted_ids_cache_key) { calculate_sorted_ids }
      end

      def sorted_ids_cache_key
        cache_prefix = self.class.name.demodulize.tableize.tr('_', '-')
        "#{cache_prefix}-#{object_manager_attribute.cache_key_with_version}-#{Translation.all.cache_key_with_version}"
      end

      def calculate_sorted_ids
        names_and_ids = fetch_names_and_ids
        names_and_ids = translate(names_and_ids)
        names_and_ids = sort(names_and_ids)

        build_id_string(names_and_ids).join(',')
      end

      def meta_value_name
        object.connection.quote_column_name("_advanced_sorting_#{object.name}_#{column}")
      end

      def adjusted_column
        raw_selectors_quoted_column(object_manager_attribute.name)
      end

      def object_manager_attribute
        @object_manager_attribute ||= ObjectManager::Attribute.get(object: object.name, name: self.class.column_name(input, object))
      end

      def translate(names_and_ids)
        return names_and_ids if !translate?

        translations = Translation.translate_all locale, *names_and_ids.map(&:second)

        names_and_ids.each do |name_and_id|
          name_and_id << translations[name_and_id.second]
        end

        names_and_ids
      end

      def build_id_string(names_and_ids)
        names_and_ids.map do |name_and_id|
          "'#{ApplicationModel.connection.quote_string(name_and_id.first)}'"
        end
      end

      def translate?
        object_manager_attribute.data_option[:translate]
      end

      def historical_options
        object_manager_attribute.data_option[:historical_options] || {}
      end
    end
  end
end
