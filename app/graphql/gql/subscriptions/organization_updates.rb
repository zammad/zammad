# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class OrganizationUpdates < BaseSubscription
    description 'Updates to organization records'

    include Gql::Subscriptions::Concerns::CanInitialResult

    unique_argument_id_key 'organizationId'

    argument :organization_id, GraphQL::Types::ID, loads: Gql::Types::OrganizationType, description: 'Organization identifier'

    field :organization, Gql::Types::OrganizationType, description: 'Updated organization'

    def subscribe(organization:, initial:)
      return {} if !initial

      { organization: }
    end

    def update(organization:, initial:)
      { organization: object }
    end
  end
end
