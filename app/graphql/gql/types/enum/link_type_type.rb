# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class LinkTypeType < BaseEnum
    description 'Link type'

    value 'normal', 'Equally related'
    value 'parent', 'Target is parent of source'
    value 'child', 'Target is child of source'
  end
end
