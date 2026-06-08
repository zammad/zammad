# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AI::Analytics
  class MetadataType < Gql::Types::BaseObject
    description 'AI Analytics Metadata type that returns related run ID and usage data if present'

    field :run, Gql::Types::AI::Analytics::RunType, description: 'ID of the related AI::Analytics::Run.', null: true
    field :usage, Gql::Types::AI::Analytics::UsageType, description: 'AI analytics usage record.', null: true
    field :is_unread, Boolean, description: 'Indicates if the summary is unread by the current user.'
  end
end
