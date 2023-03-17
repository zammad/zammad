# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class OrganizationUpdates < BaseSubscription

    argument :organization_id, GraphQL::Types::ID, description: 'Organization identifier'

    description 'Updates to organization records'

    field :organization, Gql::Types::OrganizationType, description: 'Updated organization'

    def authorized?(organization_id:)
      Gql::ZammadSchema.authorized_object_from_id organization_id, type: ::Organization, user: context.current_user
    end

    def update(organization_id:)
      { organization: object }
    end
  end
end
