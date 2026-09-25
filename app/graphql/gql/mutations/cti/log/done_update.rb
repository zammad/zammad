# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Cti::Log::DoneUpdate < BaseMutation
    description 'Mark a caller log entry of the CTI integration as handled or as not handled'

    argument :id, GraphQL::Types::ID, loads: Gql::Types::Cti::LogType, as: :log, description: 'The caller log entry to update'
    argument :done, Boolean, description: 'Whether the call is handled'

    field :log, Gql::Types::Cti::LogType, description: 'The updated caller log entry'

    requires_permission 'cti.agent'

    def resolve(log:, done:)
      {
        log: Service::Cti::Log::DoneUpdate.with_current_user(context.current_user).execute(log:, done:),
      }
    end
  end
end
