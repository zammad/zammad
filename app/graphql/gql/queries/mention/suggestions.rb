# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Mention::Suggestions < BaseQuery
    description 'Suggestions for mentionable users in a new ticket article'

    argument :query, String, description: 'User to search for'
    argument :group, GraphQL::Types::ID, description: 'A group to which the Users have to be allocated to'

    type [Gql::Types::UserType], null: true

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(query:, group:)
      ::User.search({
                      query:        query,
                      group_ids:    { Gql::ZammadSchema.verified_object_from_id(group, type: ::Group)&.id => 'read' },
                      role_ids:     Role.with_permissions('ticket.agent'),
                      current_user: context.current_user,
                    })
    end
  end
end
