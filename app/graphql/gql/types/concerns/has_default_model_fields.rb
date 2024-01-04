# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Concerns::HasDefaultModelFields
  extend ActiveSupport::Concern

  included do
    global_id_field :id

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Create date/time of the record'
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Last update date/time of the record'
  end
end
