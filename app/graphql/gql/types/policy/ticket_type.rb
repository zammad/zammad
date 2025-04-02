# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Policy::TicketType < Policy::DefaultType
    description 'Access ticket specific Pundit policy queries for the current object and user.'

    field :follow_up, Boolean, null: false, description: 'Is the user allowed to create a follow-up for this ticket?'
    field :agent_read_access, Boolean, null: false, description: 'Does the user have agent-level read access to this ticket?'
    field :agent_update_access, Boolean, null: false, description: 'Does the user have agent-level update access to this ticket?'
    field :create_mentions, Boolean, null: false, description: 'Is the user allowed to create user subscriptions for this ticket?'

    def follow_up
      pundit(:follow_up?)
    end

    def agent_read_access
      pundit(:agent_read_access?)
    end

    def agent_update_access
      pundit(:agent_update_access?)
    end

    def create_mentions
      pundit(:create_mentions?)
    end
  end
end
