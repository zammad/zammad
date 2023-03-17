# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Import
  module OTRS
    class DynamicField
      class Checkbox < Import::OTRS::DynamicField
        def init_callback(dynamic_field)
          @attribute_config.merge!(
            data_type:   'boolean',
            data_option: {
              default:   dynamic_field['Config']['DefaultValue'] == '1',
              options:   {
                true  => 'Yes',
                false => 'No',
              },
              null:      true,
              translate: true,
            }
          )
        end
      end
    end
  end
end
