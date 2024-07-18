# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User
  class TaskbarItemEntityType < Gql::Types::BaseUnion
    description 'Objects representing taskbar item entity'
    possible_types Gql::Types::UserType,
                   Gql::Types::OrganizationType,
                   Gql::Types::TicketType,
                   Gql::Types::User::TaskbarItemEntity::TicketCreateType
  end
end
