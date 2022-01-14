# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
