# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Checklist::Templates < BaseQuery
    include Gql::Concerns::EnsuresChecklistFeatureActive

    description 'Fetch checklist templates'

    argument :only_active, Boolean, required: false, default_value: false, description: 'Fetch only active templates'

    type [Gql::Types::Checklist::TemplateType, { null: false }], null: false

    def self.authorize(_obj, ctx)
      ensure_checklist_feature_active!
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def resolve(only_active:)
      only_active ? ::ChecklistTemplate.where(active: true) : ::ChecklistTemplate.all
    end
  end
end
