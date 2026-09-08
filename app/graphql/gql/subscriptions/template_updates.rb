# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TemplateUpdates < BaseSubscription

    # This subscription must not be broadcastable as it sends different data depending on
    #   the templates the subscriber is allowed to see (see TemplatePolicy::Scope).

    description 'Updates to ticket templates'

    argument :only_active, Boolean, required: false, default_value: false, description: 'Fetch only active templates'

    field :templates, [Gql::Types::TemplateType, { null: false }], description: 'Current ticket templates'

    requires_permission 'ticket.agent'

    def update(only_active:)
      templates = Pundit.policy_scope!(context.current_user, Template)
      templates = templates.active if only_active

      { templates: templates }
    end
  end
end
