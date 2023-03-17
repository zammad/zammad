# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::FormUpdater
  class RelationFieldType < Gql::Types::BaseInputObject

    description 'Represents the relation field information.'

    argument :name, String, description: 'Field name of the relation field'
    # TODO: Add enum type for relation
    argument :relation, String, description: 'Relation name for the current field (e.g. group)'
    argument :filter_ids, [Integer], required: false, description: 'Optional filter ids from the frontend'
  end
end
