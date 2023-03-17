# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Import
  module OTRS
    class DynamicField
      class Date < Import::OTRS::DynamicField
        def init_callback(dynamic_field)
          @attribute_config.merge!(
            data_type:   'date',
            data_option: {
              future: dynamic_field['Config']['YearsInFuture'] != '0',
              past:   dynamic_field['Config']['YearsInPast'] != '0',
              diff:   dynamic_field['Config']['DefaultValue'].to_i / 60 / 60 / 24,
              null:   true,
            }
          )
        end
      end
    end
  end
end
