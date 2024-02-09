# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ImportJobType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Import job information'

    field :name, String, null: false
    field :started_at, GraphQL::Types::ISO8601DateTime, null: true
    field :finished_at, GraphQL::Types::ISO8601DateTime, null: true
    field :result, GraphQL::Types::JSON, null: true
  end
end
