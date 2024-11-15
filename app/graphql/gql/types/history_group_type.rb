# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class HistoryGroupType < Gql::Types::BaseObject
    description 'History record'

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Date and time of the history record'
    field :records, [HistoryRecordType, { null: false }], null: false, description: 'Records of the history record'
  end
end
