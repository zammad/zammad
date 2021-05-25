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
