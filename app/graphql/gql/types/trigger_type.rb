# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Rudimentary implementation of TriggerType to make history work.
module Gql::Types
  class TriggerType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField

    description 'Triggers'

    field :name, String, null: false, description: 'Name of the trigger'
  end
end
