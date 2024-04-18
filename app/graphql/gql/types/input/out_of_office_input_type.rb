# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class OutOfOfficeInputType < Gql::Types::BaseInputObject
    description 'Out of office information'

    argument :enabled, Boolean, required: true, description: 'Out of office enabled?'
    argument :text, String, required: false, description: 'Out of office message'
    argument :start_at, GraphQL::Types::ISO8601Date, required: false, description: 'Out of office date range'
    argument :end_at, GraphQL::Types::ISO8601Date, required: false, description: 'Out of office date range'
    argument :replacement_id, GraphQL::Types::ID, required: false, description: 'User ID of replacement',
      loads: Gql::Types::UserType
  end
end
