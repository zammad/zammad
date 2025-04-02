# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Macros < BaseQuery
    description 'Returns a list of macros'

    argument :group_ids, [GraphQL::Types::ID], loads: Gql::Types::GroupType do
      description 'Filter macros by group assignment, must have no group or all groups assigned.'
    end

    type [Gql::Types::MacroType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(groups:)
      macros_with_any_group = Macro.available_in_groups(groups)
      return macros_with_any_group if groups.length <= 1

      group_ids = groups.map(&:id)
      macros_with_any_group.filter do |macro|
        macro.group_ids.empty? || (group_ids - macro.group_ids).empty?
      end
    end
  end
end
