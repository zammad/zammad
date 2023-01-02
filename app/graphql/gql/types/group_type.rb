# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class GroupType < Gql::Types::BaseObject
    include Gql::Concerns::IsModelObject
    include Gql::Concerns::HasInternalNoteField
    include Gql::Concerns::HasPunditAuthorization

    description 'Groups'

    # field :signature_id, Integer
    # field :email_address_id, Integer
    field :name, String
    field :assignment_timeout, Integer
    field :follow_up_possible, String, null: false
    field :follow_up_assignment, Boolean, null: false
    field :active, Boolean, null: false
  end
end
