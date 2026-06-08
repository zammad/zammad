# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class TextModule::Suggestions < BaseQuery

    description 'Search for text modules and return them with variable interpolation'

    argument :query,    String, description: 'Query from the autocomplete field'
    argument :limit,    Integer, required: false, description: 'Limit for the amount of entries'
    argument :group_id, GraphQL::Types::ID, loads: Gql::Types::GroupType, required: false, description: 'Group to filter by'
    argument :ticket_id, GraphQL::Types::ID, required: false, description: 'Optional ticket this is going to be inserted into'

    type [Gql::Types::TextModuleType], null: false

    requires_permission 'ticket.agent'

    def resolve(query:, group: nil, ticket_id: nil, template_render_context: nil, limit: 10)
      permission = ticket_id.present? ? :read : :create

      scope = TextModulePolicy::Scope
        .new(context.current_user, ::TextModule)
        .resolve(context: permission)

      if group
        scope = scope.available_in_groups(group)
      end

      scope.where('((text_modules.name ILIKE :query) OR (text_modules.keywords ILIKE :query))', query: "%#{SqlHelper.quote_like(query.strip)}%")
        .limit(limit || 10)
        .reorder(:name)
    end
  end
end
