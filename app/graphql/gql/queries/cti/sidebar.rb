# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Cti::Sidebar < BaseQuery
    description 'Fetch the counter and the ringing calls the navigation entry of the CTI integration shows'

    requires_permission 'cti.agent'

    type Gql::Types::Cti::SidebarType, null: false

    def resolve(...)
      ::Service::Cti::Log::List
        .with_current_user(context.current_user)
        .execute
    end
  end
end
