# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class GroupType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Groups'

    # field :signature_id, Integer
    # field :email_address_id, Integer
    field :name, String
    field :assignment_timeout, Integer
    field :follow_up_possible, String, null: false
    field :follow_up_assignment, Boolean, null: false
    field :active, Boolean, null: false
    field :email_address, Gql::Types::Email::AddressType

    def email_address
      return nil if !EmailAddress.exists? @object.email_address_id

      email_address = @object.email_address

      { name: email_address.realname, email_address: email_address.email }
    end
  end
end
