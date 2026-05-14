# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Bulk::Selector < Service::Base
  MAX_TICKET_IDS = 2_000
  ALLOWED_ATTRIBUTES = %i[id group_id].freeze

  attr_reader :selector, :attribute

  requires_current_user!

  def initialize(selector:, attribute: :id)
    @selector  = selector
    @attribute = attribute
  end

  def execute
    if !selector[:entity_ids].nil? # Allow empty array for entity_ids
      selector[:entity_ids].take(MAX_TICKET_IDS)
    elsif selector[:overview].present?
      overview_entity_ids(selector[:overview])
    elsif selector[:search_query].present? || selector[:search_filter].present?
      search_entity_ids(selector[:search_query], selector[:search_filter])
    else
      raise ArgumentError, 'Invalid selector: one of entity_ids, overview, or pair of search_query and search_filter must be provided.' # rubocop:disable Zammad/DetectTranslatableString
    end
  end

  private

  def return_attribute
    raise ArgumentError, "Invalid attribute: #{attribute}. Supported attributes are #{ALLOWED_ATTRIBUTES.join(', ')}." if ALLOWED_ATTRIBUTES.exclude?(attribute)

    attribute
  end

  def overview_entity_ids(overview)
    tickets = Ticket::Overviews.tickets_for_overview(overview, current_user)

    return [] if !tickets

    tickets
      .limit(MAX_TICKET_IDS)
      .pluck(return_attribute)
  end

  def search_entity_ids(query, condition)
    Service::Search
      .execute(
        query:,
        objects: [Ticket],
        options: {
          condition:,
          search_by_index: true,
          only_ids:        return_attribute == :id,
          limit:           MAX_TICKET_IDS,
        },
      )
      .result[Ticket]
  end
end
