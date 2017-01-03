module Import
  module Zendesk
    class ObjectAttribute
      class Textarea < Import::Zendesk::ObjectAttribute
        def init_callback(_object_attribte)
          @data_option.merge!(
            type:      'textarea',
            maxlength: 255,
          )
        end

        private

        def data_type(_attribute)
          'input'
        end
      end
    end
  end
end
