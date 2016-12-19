# this require is required (hehe) because of Rails autoloading
# which causes strange behavior not inheriting correctly
# from Import::OTRS::DynamicField
require 'import/zendesk/object_attribute'

module Import
  module Zendesk
    class ObjectAttribute
      class Integer < Import::Zendesk::ObjectAttribute
        def init_callback(_object_attribte)
          @data_option.merge!(
            min: 0,
            max: 999_999_999,
          )
        end

        private

        def data_type(_attribute)
          'integer'
        end
      end
    end
  end
end
