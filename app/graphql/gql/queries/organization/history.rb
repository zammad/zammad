# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Organization::History < BaseQuery
    requires_permission 'ticket.agent', 'admin.organization'

    description 'Fetch history of an organization'

    argument :organization_id, ID, loads: Gql::Types::OrganizationType, description: 'Organization ID'

    type [Gql::Types::HistoryGroupType], null: false

    def resolve(organization:)
      Service::History::Group
        .with_current_user(context.current_user)
        .execute(object: organization)
    end
  end
end
