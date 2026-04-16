# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Bulk::Selector < Service::Base
  MAX_TICKET_IDS = 2_000
  ALLOWED_ATTRIBUTES = %i[id group_id].freeze

  attr_reader :user, :selector, :attribute

  def initialize(user:, selector:, attribute: :id)
    @user      = user
    @selector  = selector
    @attribute = attribute

    super()
  end

  def execute
    if !selector[:entity_ids].nil? # Allow empty array for entity_ids
      selector[:entity_ids].take(MAX_TICKET_IDS)
    elsif selector[:overview].present?
      overview_entity_ids(selector[:overview])
    elsif selector[:search_query].present?
      search_entity_ids(selector[:search_query])
    else
      raise ArgumentError, 'Invalid selector: one of entity_ids, overview, or search_query must be provided.' # rubocop:disable Zammad/DetectTranslatableString
    end
  end

  private

  def return_attribute
    raise ArgumentError, "Invalid attribute: #{attribute}. Supported attributes are #{ALLOWED_ATTRIBUTES.join(', ')}." if ALLOWED_ATTRIBUTES.exclude?(attribute)

    attribute
  end

  def overview_entity_ids(overview)
    tickets = Ticket::Overviews.tickets_for_overview(overview, user)

    return [] if !tickets

    tickets
      .limit(MAX_TICKET_IDS)
      .pluck(return_attribute)
  end

  def search_entity_ids(query)
    Service::Search
      .new(
        current_user: user,
        query:,
        objects:      [Ticket],
        options:      { only_ids: return_attribute == :id, limit: MAX_TICKET_IDS }
      )
      .execute
      .result[Ticket]
  end
end
