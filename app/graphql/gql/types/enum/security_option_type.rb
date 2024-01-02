# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class SecurityOptionType < BaseEnum
    description 'Ticket article security options for email security methods'

    value 'encryption', 'Encrypt article'
    value 'sign',       'Sign article'
  end
end
