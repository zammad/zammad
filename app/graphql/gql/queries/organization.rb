# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Organization < BaseQuery
    description 'Fetch an organization by ID'

    argument :organization, Gql::Types::Input::Locator::OrganizationInputType, description: 'Organization locator'

    type Gql::Types::OrganizationType, null: false

    def resolve(organization:)
      organization
    end
  end
end
