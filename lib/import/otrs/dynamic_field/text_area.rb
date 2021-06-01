# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class DynamicField
      class TextArea < Import::OTRS::DynamicField
        def init_callback(dynamic_field)
          @attribute_config.merge!(
            data_type:   'textarea',
            data_option: {
              default: dynamic_field['Config']['DefaultValue'],
              rows:    dynamic_field['Config']['Rows'],
              null:    true,
            }
          )
        end
      end
    end
  end
end
