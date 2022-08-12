# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Organization < BaseQuery

    description 'Fetch an organization by ID'

    argument :organization_id, GraphQL::Types::ID, required: true, description: 'ID of the organization'

    type Gql::Types::OrganizationType, null: false

    def resolve(organization_id:)
      Gql::ZammadSchema.verified_object_from_id(organization_id, type: ::Organization)
    end
  end
end
