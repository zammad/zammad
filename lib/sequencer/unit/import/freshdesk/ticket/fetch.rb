# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Ticket::Fetch < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Freshdesk::Requester

  uses :resource

  # Fetch additional data such as attachments which is not included
  #   in the ticket list endpoint.
  def process
    resource.merge!(fetch_ticket)
  end

  private

  def fetch_ticket
    response = request(
      api_path: "tickets/#{resource['id']}",
    )

    JSON.parse(response.body)
  rescue => e
    logger.error "Error when fetching ticket data for ticket #{resource['id']}"
    logger.error e
    {}
  end
end
