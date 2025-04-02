# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class HistoryRecordType < Gql::Types::BaseObject
    description 'History record'

    field :issuer, Gql::Types::HistoryRecordIssuerType, null: false, description: 'User or system service who created the history record'
    field :events, [HistoryRecordEventType, { null: false }], null: false, description: 'Events of the history record'
  end
end
