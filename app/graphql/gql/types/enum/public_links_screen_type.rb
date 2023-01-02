# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class PublicLinksScreenType < BaseEnum
    description 'All available public links screens'

    build_string_list_enum PublicLink::AVAILABLE_SCREENS
  end
end
