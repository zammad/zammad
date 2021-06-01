# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Tag
            class Item < Sequencer::Unit::Common::Provider::Named

              uses :resource

              def item
                resource.id
              end
            end
          end
        end
      end
    end
  end
end
