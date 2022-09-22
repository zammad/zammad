# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::FormUpdater
  class MetaInputType < Gql::Types::BaseInputObject

    description 'Represents the form meta information.'

    argument :initial, Boolean, required: false, description: 'Initial form schema request'
    argument :changed_field, Gql::Types::Input::FormUpdater::ChangedFieldInputType, required: false, description: 'Changed field information'
    argument :form_id, Gql::Types::FormIdType, required: true, description: 'Generated frontend form ID'
  end
end
