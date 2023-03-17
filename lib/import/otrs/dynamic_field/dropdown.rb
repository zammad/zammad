# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Import
  module OTRS
    class DynamicField
      class Dropdown < Import::OTRS::DynamicField
        def init_callback(dynamic_field)
          @attribute_config.merge!(
            data_type:   'select',
            data_option: {
              default:    '',
              multiple:   false,
              options:    dynamic_field['Config']['PossibleValues'],
              nulloption: dynamic_field['Config']['PossibleNone'] == '1',
              null:       true,
              translate:  dynamic_field['Config']['TranslatableValues'] == '1',
            }
          )
        end

        private

        def skip?(dynamic_field)
          !dynamic_field['Config']['PossibleValues']
        end
      end
    end
  end
end
