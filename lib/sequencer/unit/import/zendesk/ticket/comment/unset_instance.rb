# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            class UnsetInstance < Sequencer::Unit::Common::UnsetAttributes

              uses :instance
            end
          end
        end
      end
    end
  end
end
