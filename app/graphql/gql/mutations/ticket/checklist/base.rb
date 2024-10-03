# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Base < BaseMutation
    include Gql::Concerns::EnsuresChecklistFeatureActive

    description 'Base class for checklist mutations.'

    def self.authorize(_obj, ctx)
      ensure_checklist_feature_active!
      ctx.current_user.permissions?(['ticket.agent'])
    end
  end
end
