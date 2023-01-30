# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class TaskbarAppType < BaseEnum
    description 'All taskbar app values'

    build_string_list_enum Taskbar::TASKBAR_APPS
  end
end
