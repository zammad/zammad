# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Organization < BaseQuery
    description 'Fetch an organization by ID'

    argument :organization_id, GraphQL::Types::ID, loads: Gql::Types::OrganizationType, description: 'Organization ID'

    type Gql::Types::OrganizationType, null: false

    def resolve(organization:)
      organization
    end
  end
end
