# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Ticket
          class Tags < Sequencer::Unit::Common::Model::Tags

            uses :resource

            private

            def tags
              resource['tags']
            end
          end
        end
      end
    end
  end
end
