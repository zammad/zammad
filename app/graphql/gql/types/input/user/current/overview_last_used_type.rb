# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User::Current
  class OverviewLastUsedType < Gql::Types::BaseInputObject
    description 'Hold last used information for an overview'

    argument :overview_id, GraphQL::Types::ID, loads: Gql::Types::OverviewType, description: 'The overview'
    argument :last_used_at, GraphQL::Types::ISO8601DateTime, description: 'When the overview was last used'
  end
end
