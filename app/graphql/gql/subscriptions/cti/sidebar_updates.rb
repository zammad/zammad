# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Cti::SidebarUpdates < BaseSubscription
    description 'Updates to what the navigation entry of the CTI integration shows for the current user'

    subscription_scope :current_user_id

    requires_permission 'cti.agent'

    field :sidebar, Gql::Types::Cti::SidebarType, null: true, description: 'The current state, resolved like the ctiSidebar query'

    # Without a payload: the state is recomputed for the subscriber, and a destroyed call
    #   could not be reloaded on the subscriber side anyway.
    def self.trigger_for(user)
      trigger(nil, scope: user.id)
    end

    # Recomputed for the subscriber rather than derived from the triggering call, so the
    #   payload can replace the query result as a whole.
    def update
      { sidebar: ::Service::Cti::Log::List.with_current_user(context.current_user).execute }
    end
  end
end
