# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# this require is required (hehe) because of Rails autoloading
# which causes strange behavior not inheriting correctly
# from Import::OTRS::DynamicField
require_dependency 'import/zendesk/object_attribute/base'

module Import
  class Zendesk
    module ObjectAttribute
      class Integer < Import::Zendesk::ObjectAttribute::Base

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
