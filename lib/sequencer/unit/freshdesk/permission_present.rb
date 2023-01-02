# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Freshdesk::PermissionPresent < Sequencer::Unit::Common::Provider::Named
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
