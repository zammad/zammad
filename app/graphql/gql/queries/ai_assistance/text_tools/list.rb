# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AIAssistance::TextTools::List < BaseQuery

    description 'Get a list of available AI text tools'

    argument :limit, Integer, required: false, description: 'Maximum number of items to return'
    argument :group_id, GraphQL::Types::ID, loads: Gql::Types::GroupType, required: false, description: 'Filter by a specific group'
    argument :ticket_id, GraphQL::Types::ID, required: false, description: 'Optional ticket this is going to be inserted into'

    type [Gql::Types::AI::TextToolType], null: false

    requires_permission 'ticket.agent'

    def resolve(limit: 50, group: nil, ticket_id: nil)
      permission = ticket_id.present? ? :read : :create

      scope = AI::TextToolPolicy::Scope
        .new(context.current_user, ::AI::TextTool)
        .resolve(context: permission)

      if group
        scope = scope.available_in_groups(group)
      end

      scope
        .limit(limit || 50)
        .reorder(:name)
    end
  end
end
