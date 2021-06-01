# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class FieldMap < Sequencer::Unit::Common::Provider::Named

          def field_map
            {}
          end
        end
      end
    end
  end
end
