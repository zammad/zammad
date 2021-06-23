# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
