# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Calendar::IcsFile::Events < BaseQuery

    description 'Fetch events from ICS file'

    argument :file_id, GraphQL::Types::ID, loads: Gql::Types::StoredFileType, description: 'The file to be parsed for events.', required: true

    type [Gql::Types::Calendar::IcsFile::EventType], null: false

    def resolve(file:)
      calendar_data = ::Service::Calendar::IcsFile::Parse
        .new(current_user: context.current_user)
        .execute(file:)

      return [] if calendar_data.blank? || calendar_data[:events].blank?

      calendar_data[:events]
    end
  end
end
