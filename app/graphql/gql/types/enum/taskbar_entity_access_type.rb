# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TaskbarEntityAccessType < BaseEnum
    description 'All taskbar entity access type values'

    value 'Granted', 'Access to this entity is granted'
    value 'Forbidden', 'Access to this entity is forbidden'
    value 'NotFound', 'The entity could not be found'
  end
end
