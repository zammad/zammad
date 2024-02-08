# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class PermissionAccessType < BaseEnum
    description 'Different user access levels'

    value 'read'
    value 'create'
    value 'change'
    value 'overview'
    value 'full'
  end
end
