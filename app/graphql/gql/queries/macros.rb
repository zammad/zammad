# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Macros < BaseQuery
    description 'Returns a list of macros'

    argument :selector, Gql::Types::Input::Ticket::Macros::SelectorInputType, description: 'The selector for ticket macros. Macros will be filtered by group assignment, must have no group or all groups assigned.'

    type [Gql::Types::MacroType], null: false

    requires_permission 'ticket.agent'

    def resolve(selector:)
      group_ids = Service::Ticket::Bulk::Selector
        .new(user: context.current_user, selector:, attribute: :group_id)
        .execute

      macros_with_any_group = Macro.available_in_groups(group_ids).sort_by(&:name)
      return macros_with_any_group if group_ids.length <= 1

      macros_with_any_group.filter do |macro|
        macro.group_ids.empty? || (group_ids - macro.group_ids).empty?
      end
    end
  end
end
