# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class SecurityInputType < Gql::Types::BaseInputObject
    description 'Represents the security attributes to be used in ticket article create/update.'

    argument :method, Gql::Types::Enum::SecurityStateTypeType, required: true, description: 'Security method.'
    argument :options, [Gql::Types::Enum::SecurityOptionType], required: true, description: 'Enabled security options.'
  end
end
