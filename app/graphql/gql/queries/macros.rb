# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Macros < BaseQuery
    description 'Returns a list of macros'

    argument :group_id, GraphQL::Types::ID, description: 'The group of the macros to look for.', loads: Gql::Types::GroupType

    type [Gql::Types::MacroType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(group:)
      Macro.available_in_groups(group)
    end
  end
end
