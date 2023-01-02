# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Kayako::Connected < Sequencer::Unit::Common::Provider::Named
  extend ::Sequencer::Unit::Import::Kayako::Requester

  private

  def connected
    response = self.class.perform_request(
      api_path: 'me',
    )
    response.is_a?(Net::HTTPOK)
  rescue => e
    logger.error e
    nil
  end
end
