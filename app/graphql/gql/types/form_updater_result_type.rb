# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class FormUpdaterResultType < Gql::Types::BaseObject

    description 'Holds the fields and flags information for an form updater resolver.'

    field :fields, GraphQL::Types::JSON, null: false
    field :flags, GraphQL::Types::JSON, null: false
    field :option_signatures, GraphQL::Types::JSON, null: false do
      description 'Signature of the current option list of a field, by field name. It is returned also when the options are not, because the form holds the list with this signature already.'
    end
  end
end
