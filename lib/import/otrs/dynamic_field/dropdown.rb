# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Import
  module OTRS
    class DynamicField
      class Dropdown < Import::OTRS::DynamicField
        include Import::OTRS::DynamicField::Mixin::HasOptions

        def init_callback(dynamic_field)
          tree_select = dynamic_field['Config']['TreeView'] == '1'

          @attribute_config.merge!(
            data_type:   tree_select ? 'tree_select' : 'select',
            data_option: {
              default:    '',
              multiple:   false,
              options:    option_list(dynamic_field['Config']['PossibleValues'], tree_select),
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
