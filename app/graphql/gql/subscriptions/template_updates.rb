# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TemplateUpdates < BaseSubscription

    description 'Updates to ticket templates'

    broadcastable true

    argument :only_active, Boolean, required: false, default_value: false, description: 'Fetch only active templates'

    field :templates, [Gql::Types::TemplateType, { null: false }], description: 'Current ticket templates'

    def authorized?(only_active:)
      context.current_user.permissions?(['ticket.agent', 'ticket.customer'])
    end

    def update(only_active:)
      {
        templates: only_active ? Template.active : Template.all
      }
    end
  end
end
