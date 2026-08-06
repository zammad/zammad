# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Jira::Connected < Sequencer::Unit::Common::Provider::Named
  extend ::Sequencer::Unit::Import::Jira::Requester

  private

  def connected
    response = self.class.perform_request(
      method:   :get,
      api_path: 'myself',
    )

    response.is_a?(Net::HTTPOK)
  rescue => e
    logger.error e
    nil
  end
end
