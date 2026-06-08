# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TaskbarStateUpdateType < BaseEnum
    description 'All taskbar state update type values'

    value 'changed', 'The taskbar item state has changed'
    value 'reset', 'The taskbar item state has been reset'
  end
end
