# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class SecurityOptionType < BaseEnum
    description 'Ticket article security options, e.g. for S/MIME'

    value 'encryption', 'Encrypt article'
    value 'sign',       'Sign article'
  end
end
