# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Templates < BaseQuery

    description 'Fetch ticket templates'

    argument :only_active, Boolean, required: false, default_value: false, description: 'Fetch only active templates'

    type [Gql::Types::TemplateType, { null: false }], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['admin.template', 'ticket.agent'])
    end

    def resolve(only_active:)
      only_active ? Template.active : Template.all
    end
  end
end
