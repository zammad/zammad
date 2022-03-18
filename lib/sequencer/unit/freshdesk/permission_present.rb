# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Freshdesk
      class PermissionPresent < Sequencer::Unit::Common::Provider::Named
        extend ::Sequencer::Unit::Import::Freshdesk::Requester

        private

        def permission_present
          response = self.class.perform_request(
            api_path: 'agents',
          )

          response.is_a?(Net::HTTPOK)
        rescue => e
          logger.error e
          nil
        end
      end
    end
  end
end
