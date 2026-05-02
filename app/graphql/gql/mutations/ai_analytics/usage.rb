# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class AIAnalytics::Usage < BaseMutation
    description 'Record usage of an AI result for purposes of analytics'

    argument :ai_analytics_run_id, GraphQL::Types::ID, loads: Gql::Types::AI::Analytics::RunType, description: 'ID of the AI analytics run to record the usage for.', required: true
    argument :input, Gql::Types::Input::AI::Analytics::UsageInputType, description: 'Input for the AI analytics usage.', required: false

    field :usage, Gql::Types::AI::Analytics::UsageType, description: 'AI analytics usage record.'

    def resolve(ai_analytics_run:, input:)
      usage = Service::AI::Analytics::UpsertUsage
        .with_current_user(context.current_user)
        .execute(ai_analytics_run, **input)

      {
        usage:,
      }
    end
  end
end
