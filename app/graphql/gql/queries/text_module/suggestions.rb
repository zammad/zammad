# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class TextModule::Suggestions < BaseQuery

    description 'Search for text modules and return them with variable interpolation'

    argument :query, String, description: 'Query from the autocomplete field'
    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'

    type [Gql::Types::TextModuleType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def resolve(query:, template_render_context: nil, limit: 10)
      find_text_modules(query: query, limit: limit || 10)
    end

    def find_text_modules(query:, limit:)
      ::TextModule.joins('LEFT OUTER JOIN groups_text_modules ON groups_text_modules.text_module_id = text_modules.id')
        .distinct
        .where('((text_modules.name LIKE :query) OR (text_modules.keywords LIKE :query))', query: "%#{query.strip}%")
        .where(active: true)
        .where(where_agent_having_groups)
        .limit(limit)
        .order(:name)
    end

    private

    def where_agent_having_groups
      no_assigned_groups = 'groups_text_modules.group_id IS NULL'

      groups = context.current_user.groups.access(:read)
      if groups.any?
        groups_matcher = groups.map(&:id).join(',')
        return " (#{no_assigned_groups} OR (groups_text_modules.group_id IN (#{groups_matcher})))"
      end

      no_assigned_groups
    end
  end
end
