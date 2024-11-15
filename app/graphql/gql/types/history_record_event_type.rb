# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class HistoryRecordEventType < Gql::Types::BaseObject
    description 'History record event'

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Date and time of the event'
    field :action, String, null: false, description: 'Action of the event'
    field :object, Gql::Types::HistoryRecordEventObjectType, null: false, description: 'Object of the event', resolver_method: :resolve_object_id
    field :attribute, String, null: true, description: 'Attribute of the event'
    field :changes, GraphQL::Types::JSON, null: true, description: 'Changes of the event'
  end

  def resolve_object(object, _context)
    object.object_id
  end
end
