# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Checklist::TemplateUpdates < BaseSubscription
    include Gql::Concerns::EnsuresChecklistFeatureActive

    description 'Subscription for checklist template changes.'

    argument :only_active, Boolean, required: false, default_value: false, description: 'Fetch only active templates'

    field :checklist_templates, [Gql::Types::Checklist::TemplateType, { null: false }], description: 'Checklist templates'

    def self.authorize(_obj, ctx)
      ensure_checklist_feature_active!
      super
    end

    def authorized?(only_active:)
      context.current_user.permissions?('ticket.agent')
    end

    def update(only_active:)
      { checklist_templates: only_active ? ::ChecklistTemplate.where(active: true) : ::ChecklistTemplate.all }
    end
  end
end
