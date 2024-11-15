# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Rudimentary implementation of JobType to make history work.
module Gql::Types
  class JobType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField

    description 'Jobs'

    field :name, String, null: false, description: 'Name of the job'
  end
end
