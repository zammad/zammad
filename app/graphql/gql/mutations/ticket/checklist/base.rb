# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Base < BaseMutation
    description 'Base class for checklist mutations.'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end
  end
end
