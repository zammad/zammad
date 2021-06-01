# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  class Zendesk
    module ObjectAttribute
      class Base

        def initialize(object, name, attribute)

          initialize_data_option(attribute)
          init_callback(attribute)

          add(object, name, attribute)
        end

        private

        def init_callback(_attribute); end

        def add(object, name, attribute)
          ObjectManager::Attribute.add( attribute_config(object, name, attribute) )
          ObjectManager::Attribute.migration_execute(false)
        rescue
          # rubocop:disable Style/SpecialGlobalVars
          raise $!, "Problem with ObjectManager Attribute '#{name}': #{$!}", $!.backtrace
          # rubocop:enable Style/SpecialGlobalVars
        end

        def attribute_config(object, name, attribute)
          {
            object:        object.to_s,
            name:          name,
            display:       attribute.title,
            data_type:     data_type(attribute),
            data_option:   @data_option,
            editable:      !attribute.removable,
            active:        attribute.active,
            screens:       screens(attribute),
            position:      attribute.position,
            created_by_id: 1,
            updated_by_id: 1,
          }
        end

        def screens(attribute)
          config = {
            view: {
              '-all-' => {
                shown: true,
              },
            }
          }

          return config if !attribute.visible_in_portal && attribute.required_in_portal

          {
            edit: {
              Customer: {
                shown: attribute.visible_in_portal,
                null:  !attribute.required_in_portal,
              },
            }.merge(config)
          }
        end

        def initialize_data_option(attribute)
          @data_option = {
            null: !attribute.required,
            note: attribute.description,
          }
        end

        def data_type(attribute)
          attribute.type
        end
      end
    end
  end
end
