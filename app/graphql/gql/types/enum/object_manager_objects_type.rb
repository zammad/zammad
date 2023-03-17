# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class ObjectManagerObjectsType < BaseEnum
    description 'All backend managed objects'

    build_string_list_enum ObjectManager.list_objects
  end
end
