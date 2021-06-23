# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  class Zendesk
    module ObjectAttribute
      class Regexp < Import::Zendesk::ObjectAttribute::Base

        def init_callback(object_attribte)
          @data_option.merge!(
            type:      'text',
            maxlength: 255,
            regex:     object_attribte.regexp_for_validation,
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
