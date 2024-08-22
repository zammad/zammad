# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Calendar::IcsFile::EventType < BaseObject
    description 'Event from ICS file'

    field :title, String, null: true
    field :location, String, null: true
    field :start_date, GraphQL::Types::ISO8601DateTime
    field :end_date, GraphQL::Types::ISO8601DateTime
    field :attendees, [String], null: true
    field :organizer, String, null: true
    field :description, String, null: true
  end
end
