# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# this require is required (hehe) because of Rails autoloading
# which causes strange behavior not inheriting correctly
# from Import::OTRS::DynamicField
require_dependency 'import/zendesk/object_attribute/base'

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
