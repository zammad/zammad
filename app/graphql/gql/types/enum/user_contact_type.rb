# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class UserContactType < BaseEnum
    description 'User contact option'

    value 'email', 'User email address'
    value 'phone', 'User phone number'
  end
end
