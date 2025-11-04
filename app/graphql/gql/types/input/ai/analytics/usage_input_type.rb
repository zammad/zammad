# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::AI::Analytics
  class UsageInputType < Gql::Types::BaseInputObject
    description 'Input for the AI analytics usage.'

    argument :rating, Boolean, description: 'Usage rating of the AI result.', required: false
    argument :comment, String, description: 'Usage comment on the AI result.', required: false
    argument :context, GraphQL::Types::JSON, description: 'Context data of the usage, e.g. approval status.', required: false
  end
end
