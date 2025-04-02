# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module CanSelector
  class AdvancedSorting
    module CanApplyAdvancedSorting
      extend ActiveSupport::Concern

      class_methods do
        def applicable?(input, locale, object)
          return false if locale.blank?

          attr = ObjectManager::Attribute.get(object: object.name, name: column_name(input, object))
          return false if attr.nil?

          return true if attr.data_type == data_type

          false
        end

        def data_type(name = nil)
          if name.present?
            @data_type = name
          elsif defined?(@data_type)
            @data_type
          else
            raise 'data_type not set'
          end
        end
      end
    end
  end
end
