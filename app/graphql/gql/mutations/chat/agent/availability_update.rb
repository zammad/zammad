# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Chat::Agent::AvailabilityUpdate < BaseMutation
    description 'Switch the current agent available or unavailable for chats'

    argument :active, Boolean, description: 'Whether the agent takes chats'

    field :active, Boolean, null: false, description: 'The availability as stored'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    def resolve(active:)
      {
        active: ::Service::Chat::Agent::AvailabilityUpdate.with_current_user(context.current_user).execute(active:),
      }
    end
  end
end
