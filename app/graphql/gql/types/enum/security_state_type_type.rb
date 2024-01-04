# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class SecurityStateTypeType < BaseEnum
    description 'Available email security methods'

    value 'SMIME', 'S/MIME', value: 'S/MIME'
    value 'PGP',   'PGP',    value: 'PGP'
  end
end
