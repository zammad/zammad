# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class UserType < Gql::Types::BaseObject
    include Gql::Concerns::IsModelObject
    include Gql::Concerns::HasInternalIdField
    include Gql::Concerns::HasInternalNoteField

    # Special handling for users: GraphQL allows all authenticated users
    #   to look at other user records, but only some non-sensitive fields.
    # For the other fields, proper pundit authorization to the user object
    #   is required.

    description 'Users (admins, agents and customers)'

    implements Gql::Types::ObjectAttributeValueInterface

    belongs_to :organization, Gql::Types::OrganizationType, authorize: :by_pundit

    field :firstname, String
    field :lastname, String
    field :fullname, String
    field :image, String
    field :image_source, String

    field_args(authorize: :by_pundit) do
      field :login, String
      field :email, String
      field :web, String
      field :phone, String
      field :fax, String
      field :mobile, String
      field :vip, Boolean
      field :verified, Boolean
      field :active, Boolean
      field :out_of_office, Boolean
      field :out_of_office_start_at, GraphQL::Types::ISO8601Date
      field :out_of_office_end_at, GraphQL::Types::ISO8601Date
      field :out_of_office_replacement_id, Integer
      field :preferences, GraphQL::Types::JSON
      field :permissions, Gql::Types::User::PermissionType, method: :itself
      field :tickets_count, Gql::Types::TicketCountType, method: :itself
    end

    # These fields are changeable object attributes, so manage them only via the ObjectAttributeInterface
    # field :department, String
    # field :street, String
    # field :zip, String
    # field :city, String
    # field :country, String
    # field :address, String
  end
end
