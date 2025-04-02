# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::TaskbarItemEntity
  class SearchType < Gql::Types::BaseObject
    description 'Entity representing taskbar item search'

    field :query, String
    field :model, String

  end
end
