# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  class Zendesk
    module ObjectAttribute
      class Textarea < Import::Zendesk::ObjectAttribute::Base

        def init_callback(_object_attribte)
          @data_option.merge!(
            type:      'textarea',
            maxlength: 255,
          )
        end

        private

        def data_type(_attribute)
          'textarea'
        end
      end
    end
  end
end
