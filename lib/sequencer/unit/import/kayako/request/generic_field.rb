# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        class Request < Sequencer::Unit::Common::Provider::Attribute
          class GenericField < Sequencer::Unit::Import::Kayako::Request::Generic
            def params
              super.merge(
                include: 'field_option,locale_field',
              )
            end
          end
        end
      end
    end
  end
end
