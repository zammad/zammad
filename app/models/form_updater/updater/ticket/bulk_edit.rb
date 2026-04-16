# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::BulkEdit < FormUpdater::Updater
  include FormUpdater::Concerns::ChecksCoreWorkflow

  core_workflow_screen 'overview_bulk'

  def self.required_permissions
    %w[ticket.agent]
  end

  def object_type
    ::Ticket
  end

  def resolve
    resolve = super

    # Include user object in each owner option so the avatars can be rendered correctly.
    #   Do this only after core workflow resolution, otherwise the list of options will be empty at this point.
    enrich_owner_options if meta.dig(:additional_data, 'enrichOwnerOptions')

    resolve
  end

  private

  def perform_payload
    payload = super

    input = meta[:additional_data]&.slice('entityIds', 'overviewId', 'searchQuery') || {}
    return payload if input.blank?

    # Normalize selector keys, since they are passed via arbitrary metadata structure.
    #   We are running outside of GraphQL context here, so we can't rely on argument transformers to do this for us.
    selector = normalize_selector(input)
    return payload if selector.blank?

    # Add ticket_ids to params for CoreWorkflow to determine common owners
    ticket_ids = Service::Ticket::Bulk::Selector
      .new(user: current_user, selector:)
      .execute || []

    return payload if ticket_ids.empty?

    payload['params']['ticket_ids'] = ticket_ids.join(',')

    payload
  end

  def normalize_selector(input)
    selector = {}

    if input['entityIds'].present?
      selector[:entity_ids] = input['entityIds'].map do |ticket_id|
        Gql::ZammadSchema.authorized_object_from_id(ticket_id, type: ::Ticket, user: current_user, query: :update?)&.id
      end
    elsif input['overviewId'].present?
      selector[:overview] = Gql::ZammadSchema.authorized_object_from_id(input['overviewId'], type: ::Overview, user: current_user, query: :use?)
    elsif input['searchQuery'].present?
      selector[:search_query] = input['searchQuery']
    end

    selector
  end

  def enrich_owner_options
    owner_options = result.dig('owner_id', :options) || []

    owner_options.each do |option|
      user = ::User.find_by(id: option[:value])
      next if !user

      # Serialize user without the organization relation and computed fields.
      user_serialized = ::FormUpdater::Graphql::Serializers::User.serialize(user, with_organization: false, with_computed: false)

      option[:object] = user_serialized
    end
  end
end
