class Sequencer
  class Unit
    module Zendesk
      class Connected < Sequencer::Unit::Common::Provider::Named

        uses :client

        private

        def connected
          client.current_user.id.present?
        end
      end
    end
  end
end
