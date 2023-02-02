# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::LiveUser
  class AppType < Gql::Types::BaseObject
    description 'Ticket live user app information'

    field :name, Gql::Types::Enum::TaskbarAppType, null: false
    field :editing, Boolean, null: false
    field :last_interaction, GraphQL::Types::ISO8601DateTime, null: false, description: 'Last interaction time from the user in the frontend'
  end
end
