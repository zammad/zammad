class Sequencer
  class Unit
    module Import
      module Zendesk
        module TicketField
          class Add < Sequencer::Unit::Import::Zendesk::ObjectAttribute::Add
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            skip_action :skipped

            uses :action
          end
        end
      end
    end
  end
end
