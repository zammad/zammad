# this require is required (hehe) because of Rails autoloading
# which causes strange behavior not inheriting correctly
# from Import::OTRS::DynamicField
require 'import/zendesk/object_attribute'

module Import
  module Zendesk
    class ObjectAttribute
      class Regexp < Import::Zendesk::ObjectAttribute
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
