# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class OrganizationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Organizations that users can belong to'

    implements Gql::Types::ObjectAttributeValuesInterface

    scoped_fields do
      field :name, String
      field :active, Boolean
      field :shared, Boolean
      field :vip, Boolean
      field :domain, String
      field :domain_assignment, Boolean
      field :members, Gql::Types::UserType.connection_type, description: 'Users assigned via primary organization'
      field :secondary_members, Gql::Types::UserType.connection_type, description: 'Users assigned via secondary organization'
      field :all_members, Gql::Types::UserType.connection_type, description: 'All assigned users'
      field :tickets_count, Gql::Types::TicketCountType, method: :itself
    end

    field :policy, Gql::Types::Policy::DefaultType, null: false, method: :itself
  end
end
