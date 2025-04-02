# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    attr_reader :input, :locale, :object

    def initialize(input, locale, object)
      @input  = input
      @locale = locale
      @object = object
    end

    def self.available_sorters
      [
        TranslatedRelationSort,
        UntranslatedRelationSort,
        SelectFieldSort,
        TreeSelectFieldSort,
        ExternalDataSourceFieldSort,
        BooleanFieldSort,
      ]
    end

    def calculate_sorting
      unpack_element(input)
    end

    private

    def unpack_element(elem)
      case elem
      when Array
        elem.map { |array_elem| unpack_element(array_elem) }
      when Hash
        calculate_element(elem)
      else
        elem
      end
    end

    def calculate_element(elem)
      sorter_klass = find_sorter(elem, locale, object)

      sorter_klass
        .new(elem, locale, object)
        .calculate_sorting
    end

    def find_sorter(input, locale, object)
      self.class.available_sorters.find { |elem| elem.applicable?(input, locale, object) } || DefaultSort
    end
  end
end
