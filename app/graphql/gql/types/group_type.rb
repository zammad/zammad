# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class GroupType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Groups'

    # field :signature_id, Integer
    # field :email_address_id, Integer

    field :name, String
    field :active, Boolean, null: false

    scoped_fields do
      field :email_address, Gql::Types::EmailAddressParsedType
      field :assignment_timeout, Integer
      field :follow_up_possible, String
      field :follow_up_assignment, Boolean
      field :shared_drafts, Boolean
      field :summary_generation, Gql::Types::Enum::TicketSummaryGeneration, description: 'Ticket summary generation behavior for this group'
    end

    def email_address
      return nil if !EmailAddress.exists? @object.email_address_id

      email_address = @object.email_address

      { name: email_address.name, email_address: email_address.email }
    end
  end
end
