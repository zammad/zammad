# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# This type counts user or organization tickets accessible to *current user*
# It is very similar to what TicketUserTicketCounterJob does but not the same!
# This counter is used exclusively in New Tech stack
module Gql::Types
  class TicketCountType < Gql::Types::BaseObject
    description 'Open and closed ticket information'

    field :open, Integer, null: false, description: 'Open ticket count of the related object'
    field :open_search_query, String, description: 'Open ticket search query of the related object'
    field :closed, Integer, null: false, description: 'Closed ticket count of the related object'
    field :closed_search_query, String, description: 'Closed ticket search query of the related object'

    field :organization_open, Integer, null: true, description: "Open ticket count of the related object's organizations"
    field :organization_open_search_query, String, null: true, description: "Open ticket search query of the related object's organizations"
    field :organization_closed, Integer, null: true, description: "Closed ticket count of the related object's organizations"
    field :organization_closed_search_query, String, null: true, description: "Closed ticket search query of the related object's organizations"

    def open
      ticket_count(:open)
    end

    def open_search_query
      ticket_search_query(:open)
    end

    def closed
      ticket_count(:closed)
    end

    def closed_search_query
      ticket_search_query(:closed)
    end

    def organization_open
      ticket_count(:open, for_organizations: true)
    end

    def organization_open_search_query
      ticket_search_query(:open, for_organizations: true)
    end

    def organization_closed
      ticket_count(:closed, for_organizations: true)
    end

    def organization_closed_search_query
      ticket_search_query(:closed, for_organizations: true)
    end

    private

    def ticket_count(category, for_organizations: false)
      scope = TicketPolicy::ReadScope.new(context.current_user).resolve

      scope = if for_organizations
                scope.where(organization_id: object_organizations)
              else
                scope.where(object_key_column => object.id)
              end

      scope = scope.where(state_id: ::Ticket::State.by_category(category).select(:id))

      scope.count
    end

    def ticket_search_query(category, for_organizations: false)
      object_filter = if for_organizations
                        # FIXME: The organization search query could get too long if user has many organizations.
                        #   Coupled with the state filter below, this does not scale well.
                        #   We might want to implement a different way to represent this search alias.
                        "organization_id:(#{object_organizations.join(' OR ')})"
                      else
                        "#{object_key_column}:#{object.id}"
                      end

      states = ::Ticket::State.by_category(category).pluck(:name)
      return object_filter if states.empty?

      states_query =
        if states.size > 1
          %( AND state.name:("#{states.map { |state| escape_for_es(state) }.join('" OR "')}"))
        else
          %( AND state.name:"#{escape_for_es(states.first)}")
        end

      "#{object_filter}#{states_query}"
    end

    def escape_for_es(string)
      string.gsub(%r{"}) { '\\"' }
    end

    def object_key_column
      case @object
      when ::Organization
        'organization_id'
      when ::User
        'customer_id'
      else
        raise "Unknown object type #{@object.class}"
      end
    end

    def object_organizations
      case @object
      when ::Organization
        [@object.id]
      when ::User
        @object.all_organization_ids
      else
        raise "Unknown object type #{@object.class}"
      end
    end
  end
end
