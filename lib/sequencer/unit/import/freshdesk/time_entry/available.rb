# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::TimeEntry::Available < Sequencer::Unit::Common::Provider::Attribute
  extend ::Sequencer::Unit::Import::Freshdesk::Requester

  provides :time_entry_available

  def process
    state.provide(:time_entry_available, time_entry_available)
  end

  private

  def time_entry_available
    response = self.class.perform_request(
      api_path: 'time_entries',
    )

    response.is_a?(Net::HTTPOK)
  rescue => e
    logger.info e
    nil
  end
end
