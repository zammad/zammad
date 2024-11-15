# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Rudimentary implementation of PostmasterFilterType to make history work.
module Gql::Types
  class PostmasterFilterType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField

    description 'PostmasterFilters'

    field :name, String, null: false, description: 'Name of the postmaster filter'
  end
end
