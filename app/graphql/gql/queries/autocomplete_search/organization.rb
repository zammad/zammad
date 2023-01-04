# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Organization < BaseQuery

    description 'Search for organizations'

    argument :input, Gql::Types::Input::AutocompleteSearch::OrganizationInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::OrganizationEntryType], null: false

    def resolve(input:)
      input = input.to_h
      query = input[:query]
      limit = input[:limit] || 50

      return [] if query.strip.empty?

      Service::Search.new(current_user: context.current_user).execute(
        term:    query,
        objects: [::Organization],
        options: { limit: limit, ids: customer_ids(input[:customer]) },
      ).map { |organization| coerce_to_result(organization) }
    end

    def coerce_to_result(organization)
      {
        value:        organization.id,
        label:        organization.name,
        organization: organization,
      }
    end

    private

    def customer_ids(customer)
      return nil if customer.blank?
      return nil if customer.all_organization_ids.blank?

      customer.all_organization_ids
    end
  end
end
