# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class UpdateInputType < BaseInputType
    description 'Represents the ticket attributes to be used in ticket update.'

    argument :title, Gql::Types::NonEmptyStringType, required: false, description: 'The title of the ticket.'
  end
end
