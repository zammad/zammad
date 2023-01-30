# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class LiveUserType < Gql::Types::BaseObject
    description 'Ticket live user information'

    field :user, Gql::Types::UserType, null: false
    field :editing, Boolean, null: false
    field :last_interaction, GraphQL::Types::ISO8601DateTime, null: false, description: 'Last interaction time from the user in the frontend'
    field :apps, [Gql::Types::Enum::TaskbarAppType], null: false, description: 'Apps the user is currently using to view the ticket'
  end
end
