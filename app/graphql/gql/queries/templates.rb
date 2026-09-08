# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Templates < BaseQuery

    description 'Fetch ticket templates'

    argument :only_active, Boolean, required: false, default_value: false, description: 'Fetch only active templates'

    type [Gql::Types::TemplateType, { null: false }], null: false

    requires_permission 'admin.template', 'ticket.agent'

    def resolve(only_active:)
      templates = Pundit.policy_scope!(context.current_user, Template)
      templates = templates.active if only_active

      templates.sorted
    end
  end
end
