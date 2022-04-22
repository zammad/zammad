# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        class Request < Sequencer::Unit::Common::Provider::Attribute
          class Case < Sequencer::Unit::Import::Kayako::Request::Generic
            def params
              super.merge(
                include: 'user,case_priority,case_status,channel,tag,case_type,case_field,field_option,locale_field',
                fields:  '+tags',
              )
            end
          end
        end
      end
    end
  end
end
