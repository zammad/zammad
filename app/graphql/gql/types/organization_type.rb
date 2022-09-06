# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OrganizationType < Gql::Types::BaseObject
    include Gql::Concerns::IsModelObject
    include Gql::Concerns::HasInternalIdField
    include Gql::Concerns::HasInternalNoteField
    include Gql::Concerns::HasPunditAuthorization

    description 'Organizations that users can belong to'

    implements Gql::Types::ObjectAttributeValueInterface

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
