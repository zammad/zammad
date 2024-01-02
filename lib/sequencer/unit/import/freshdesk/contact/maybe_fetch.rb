# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Contact::MaybeFetch < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Freshdesk::Requester

  uses :resource
  optional :contact_id

  # Fetch contact only, when it's not already present.
  def process
    return if contact_id.blank?

    resource.merge!(fetch_contact)
  end

  private

  def fetch_contact
    response = request(
      api_path: "contacts/#{contact_id}",
    )

    JSON.parse(response.body)
  rescue => e
    logger.error "Error when fetching contact data for contact #{contact_id}"
    logger.error e
    {}
  end
end
