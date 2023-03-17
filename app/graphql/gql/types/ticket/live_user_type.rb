# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class LiveUserType < Gql::Types::BaseObject
    description 'Ticket live user information'

    field :user, Gql::Types::UserType, null: false, is_dependent_field: true
    field :apps, [Gql::Types::Ticket::LiveUser::AppType], null: false, description: 'Different apps information from the user'
  end
end
