# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::TaskbarItemEntity
  class SearchType < Gql::Types::BaseObject
    description 'Entity representing taskbar item search'

    field :query, String
    field :model, String
    field :filters, String
    field :filter_count, Integer, hash_key: :filterCount

  end
end
