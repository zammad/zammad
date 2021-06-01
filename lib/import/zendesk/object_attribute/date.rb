# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# this require is required (hehe) because of Rails autoloading
# which causes strange behavior not inheriting correctly
# from Import::OTRS::DynamicField
require_dependency 'import/zendesk/object_attribute/base'

module Import
  class Zendesk
    module ObjectAttribute
      class Date < Import::Zendesk::ObjectAttribute::Base
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
