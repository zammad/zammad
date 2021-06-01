# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
      end
    end
  end
end
