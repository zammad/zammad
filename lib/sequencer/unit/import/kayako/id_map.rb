# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        class IdMap < Sequencer::Unit::Common::Provider::Named

          def id_map
            {}
          end
        end
      end
    end
  end
end
