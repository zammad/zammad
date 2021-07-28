# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class Resources < Sequencer::Unit::Common::Provider::Named
          include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

          uses :response

          private

          def resources
            JSON.parse(response.body)
          rescue => e
            logger.error "Won't be continued, because no response is available."
            handle_failure(e)
          end
        end
      end
    end
  end
end
