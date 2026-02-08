# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class OrganizationUpdates < BaseSubscription

    argument :organization_id, GraphQL::Types::ID, loads: Gql::Types::OrganizationType, description: 'Organization identifier'

    description 'Updates to organization records'

    field :organization, Gql::Types::OrganizationType, description: 'Updated organization'

    def update(organization:)
      { organization: object }
    end
  end
end
