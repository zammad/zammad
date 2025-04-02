# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class FormUpdaterResultType < Gql::Types::BaseObject

    description 'Holds the fields and flags information for an form updater resolver.'

    field :fields, GraphQL::Types::JSON, null: false
    field :flags, GraphQL::Types::JSON, null: false
  end
end
