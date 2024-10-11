# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TaskbarEntityType < BaseEnum
    description 'All taskbar entity values'

    build_string_list_enum Taskbar.taskbar_entities
  end
end
