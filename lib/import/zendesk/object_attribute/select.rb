# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# this require is required (hehe) because of Rails autoloading
# which causes strange behavior not inheriting correctly
# from Import::OTRS::DynamicField
require_dependency 'import/zendesk/object_attribute/base'

module Import
  class Zendesk
    module ObjectAttribute
      class Select < Import::Zendesk::ObjectAttribute::Base

        def init_callback(object_attribte)
          @data_option.merge!(
            default: '',
            options: options(object_attribte),
          )
        end

        private

        def data_type(_attribute)
          'select'
        end

        def options(object_attribte)
          result = {}
          object_attribte.custom_field_options.each do |entry|
            result[ entry['value'] ] = entry['name']
          end
          result
        end
      end
    end
  end
end
