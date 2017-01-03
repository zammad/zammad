# this require is required (hehe) because of Rails autoloading
# which causes strange behavior not inheriting correctly
# from Import::OTRS::DynamicField
require 'import/zendesk/object_attribute'

module Import
  module Zendesk
    class ObjectAttribute
      class Date < Import::Zendesk::ObjectAttribute
        def init_callback(_object_attribte)
          @data_option.merge!(
            future: true,
            past:   true,
            diff:   0,
          )
        end
      end
    end
  end
end
