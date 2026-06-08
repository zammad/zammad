# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class Bulk::PerformInputType < Gql::Types::BaseInputObject
    description 'Represents the bulk update action to be performed on the selected tickets.'

    argument :input, Gql::Types::Input::Ticket::UpdateInputType, required: false, description: 'The ticket data'
    argument :macro_id, GraphQL::Types::ID, loads: Gql::Types::MacroType, required: false, description: 'The macro to apply onto ticket'

    def prepare
      hash = to_h

      if hash.slice(:input, :macro).values.none?(&:present?)
        raise GraphQL::ExecutionError, 'At least one of input or macro_id must be provided.' # rubocop:disable Zammad/DetectTranslatableString
      end

      hash
    end
  end
end
