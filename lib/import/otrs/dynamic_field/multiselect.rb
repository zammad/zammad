module Import
  module OTRS
    class DynamicField
      class Multiselect < Import::OTRS::DynamicField
        def init_callback(dynamic_field)
          @attribute_config.merge!(
            data_type:   'select',
            data_option: {
              default:   '',
              multiple:  true,
              options:   dynamic_field['Config']['PossibleValues'],
              null:      dynamic_field['Config']['PossibleNone'] == '1',
              translate: dynamic_field['Config']['TranslatableValues'] == '1',
            }
          )
        end
      end
    end
  end
end
