# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class Checklist::ItemInputType < Gql::Types::BaseInputObject
    description 'Input fields for ticket checklist item.'

    argument :text, String, required: false, description: 'Checklist item label'
    argument :checked, Boolean, required: false, description: 'Checklist item state'
  end
end
