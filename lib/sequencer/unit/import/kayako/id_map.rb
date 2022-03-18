# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
