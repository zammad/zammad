# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class UpdateInputType < BaseInputType
    description 'Represents the ticket attributes to be used in ticket update.'

    # Arguments optional in update.
    argument :group_id, GraphQL::Types::ID, required: false, description: 'The group of the ticket.', loads: Gql::Types::GroupType
    argument :title, Gql::Types::NonEmptyStringType, required: false, description: 'The title of the ticket.'
  end
end
