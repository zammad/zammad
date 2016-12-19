module Import
  module Zendesk
    class ObjectAttribute
      class Select < Import::Zendesk::ObjectAttribute
        def init_callback(object_attribte)
          @data_option.merge!(
            default: '',
            options: options(object_attribte),
          )
        end

        private

        def data_type(_attribute)
          'select'
        end

        def options(object_attribte)
          result = {}
          object_attribte.custom_field_options.each { |entry|
            result[ entry['value'] ] = entry['name']
          }
          result
        end
      end
    end
  end
end
