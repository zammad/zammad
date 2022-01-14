# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
