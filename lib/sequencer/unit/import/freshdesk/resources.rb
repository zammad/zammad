class Sequencer
  class Unit
    module Import
      module Freshdesk
        class Resources < Sequencer::Unit::Common::Provider::Named

          uses :response

          private

          def resources
            JSON.parse(response.body)
          end
        end
      end
    end
  end
end
