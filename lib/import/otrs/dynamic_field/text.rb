# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class DynamicField
      class Text < Import::OTRS::DynamicField
        def init_callback(dynamic_field)
          @attribute_config.merge!(
            data_type:   'input',
            data_option: {
              default:   dynamic_field['Config']['DefaultValue'],
              type:      'text',
              maxlength: 255,
              null:      true,
            }
          )
        end
      end
    end
  end
end
