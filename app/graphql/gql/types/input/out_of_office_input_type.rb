# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class OutOfOfficeInputType < Gql::Types::BaseInputObject
    description 'Out of office information'

    argument :enabled, Boolean, required: true, description: 'Out of office enabled?'
    argument :text, String, required: true, description: 'Out of office message'
    argument :start_at, GraphQL::Types::ISO8601DateTime, required: true, description: 'Out of office start date'
    argument :end_at, GraphQL::Types::ISO8601DateTime, required: true, description: 'Out of office end date'
    argument :replacement, ID, required: true, description: 'User ID of replacement'
  end
end
