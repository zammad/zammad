# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::FormUpdater
  class ChangedFieldInputType < Gql::Types::BaseInputObject

    description 'Represents the form changed field information.'

    argument :name, String, required: true, description: 'Changed field name'
    argument :new_value, GraphQL::Types::JSON, required: :nullable, description: 'New value from changed field'
    argument :old_value, GraphQL::Types::JSON, required: :nullable, description: 'Old value from changed field'

  end
end
