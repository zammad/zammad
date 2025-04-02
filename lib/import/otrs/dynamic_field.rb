# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Import
  module OTRS
    class DynamicField

      def initialize(dynamic_field)
        @internal_name = self.class.convert_name(dynamic_field['Name'])

        return if already_imported?(dynamic_field)
        return if skip?(dynamic_field)

        initialize_attribute_config(dynamic_field)

        init_callback(dynamic_field)
        add
      end

      def self.convert_name(dynamic_field_name)
        dynamic_field_name.underscore.sub(%r{_id(s)?\z}, '_no\1')
      end

      private

      def init_callback(_)
        raise 'No init callback defined for this dynamic field!'
      end

      def already_imported?(dynamic_field)
        attribute = ObjectManager::Attribute.get(
          object: dynamic_field['ObjectType'],
          name:   @internal_name,
        )
        attribute ? true : false
      end

      def initialize_attribute_config(dynamic_field)

        @attribute_config = {
          object:        dynamic_field['ObjectType'],
          name:          @internal_name,
          display:       dynamic_field['Label'],
          screens:       {
            view: {
              '-all-' => {
                shown: true,
              },
            },
          },
          active:        true,
          editable:      dynamic_field['InternalField'] == '0',
          position:      dynamic_field['FieldOrder'],
          created_by_id: 1,
          updated_by_id: 1,
        }
      end

      def skip?(_dynamic_field)
        false
      end

      def add
        ObjectManager::Attribute.add(@attribute_config)
        ObjectManager::Attribute.migration_execute(false)
      end
    end
  end
end
