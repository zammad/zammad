# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    class TreeSelectFieldSort < BaseSelectFieldSort
      data_type 'tree_select'

      def self.applicable?(input, locale, object)
        applicable = super
        return false if !applicable

        attr = ObjectManager::Attribute.get(object: object.name, name: column_name(input, object))
        return false if !attr.data_option[:translate]

        true
      end

      def initialize(input, locale, object)
        super

        attr = ObjectManager::Attribute.get(object: object.name, name: self.class.column_name(input, object))
        raise "#{self.class.name} can only be used with translatable fields" if !attr.data_option[:translate]
      end

      private

      def translate(names_and_ids)
        names_and_ids.map! do |name, id|
          parts = name.split('::')
          translated = Translation.translate_all(locale, *parts).values

          [name, id, translated.join('::')]
        end

        names_and_ids
      end

      def sort(names_and_ids)
        locale_object = Locale.find_by(locale:)

        if !locale_object
          names_and_ids.sort_by!(&:first)
          return names_and_ids
        end

        comparator = TwitterCldr::Collation::Collator.new(locale_object.cldr_language_code)

        names_and_ids.sort { |a, b| comparator.compare(a.third, b.third) }
      end
    end
  end
end
