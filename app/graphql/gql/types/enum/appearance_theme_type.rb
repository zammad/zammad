# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class AppearanceThemeType < BaseEnum
    description 'Option to choose the appearance theme'

    value 'dark', 'A color scheme that uses light-colored elements on a dark background.'
    value 'light', 'A color scheme that uses dark-colored elements on a light background.'
    value 'auto', 'Prefer color scheme as indicated by the operating system.'
  end
end
