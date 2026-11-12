# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Chat::Preferences < BaseQuery
    description 'Fetch the chat preferences of the current agent, with every active topic'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    type Gql::Types::Chat::PreferencesType, null: false

    def resolve(...)
      context.current_user.preferences[:chat] || {}
    end
  end
end
