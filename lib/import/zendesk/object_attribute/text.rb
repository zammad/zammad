module Import
  module Zendesk
    class ObjectAttribute
      class Text < Import::Zendesk::ObjectAttribute
        def init_callback(_object_attribte)
          @data_option.merge!(
            type:      'text',
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
