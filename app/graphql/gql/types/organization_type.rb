# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OrganizationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization
    include Gql::Types::Concerns::HasPolicyField

    description 'Organizations that users can belong to'

    implements Gql::Types::ObjectAttributeValuesInterface

    scoped_fields do
      field :name, String
      field :active, Boolean
      field :shared, Boolean
      field :domain, String
      field :domain_assignment, Boolean
      field :members, Gql::Types::UserType.connection_type
      field :tickets_count, Gql::Types::TicketCountType, method: :itself
    end
  end
end
