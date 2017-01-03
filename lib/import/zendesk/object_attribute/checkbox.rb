module Import
  module Zendesk
    class ObjectAttribute
      class Checkbox < Import::Zendesk::ObjectAttribute
        def init_callback(_object_attribte)
          @data_option.merge!(
            default: false,
            options: {
              true  => 'yes',
              false => 'no',
            },
          )
        end

        private

        def data_type(_attribute)
          'boolean'
        end
      end
    end
  end
end
