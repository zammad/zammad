# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class UpdateMetaInputType < BaseInputType
    description 'Represents ticket update meta information to be used in ticket update.'

    argument :skip_validator, String, required: false, description: 'The ticket update validator to skip'
    argument :macro_id, GraphQL::Types::ID, loads: Gql::Types::MacroType, required: false, description: 'The macro to apply onto ticket'
  end
end
