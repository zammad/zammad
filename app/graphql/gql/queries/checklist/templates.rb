# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Checklist::Templates < BaseQuery
    description 'Fetch checklist templates'

    argument :only_active, Boolean, required: false, default_value: false, description: 'Fetch only active templates'

    type [Gql::Types::Checklist::TemplateType, { null: false }], null: false

    requires_enabled_setting 'checklist', error_message: __('The checklist feature is not active')
    requires_permission 'ticket.agent'

    def resolve(only_active:)
      only_active ? ::ChecklistTemplate.where(active: true) : ::ChecklistTemplate.all
    end
  end
end
