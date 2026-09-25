# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Cti::Logs < BaseQuery
    description 'Fetch the paginated caller log of the CTI integration, newest first'

    requires_permission 'cti.agent'

    type Gql::Types::Cti::LogType.connection_type, null: false

    def resolve(...)
      ::Service::Cti::Log::List
        .with_current_user(context.current_user)
        .execute
    end
  end
end
