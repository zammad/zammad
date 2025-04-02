# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class UserType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields # Instead of IsModelObject to have custom #created_by and #updated_by
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Users (admins, agents and customers)'

    implements Gql::Types::ObjectAttributeValuesInterface

    # Special handling for users: GraphQL allows all authenticated users
    #   to look at other user records, but only some non-sensitive fields.
    def self.nested_access_pundit_method
      :nested_show?
    end

    field :policy, Gql::Types::Policy::DefaultType, null: false, method: :itself

    scoped_fields do # rubocop:disable Metrics/BlockLength
      belongs_to :organization, Gql::Types::OrganizationType

      field :secondary_organizations, Gql::Types::OrganizationType.connection_type
      field :has_secondary_organizations, Boolean, resolver_method: :secondary_organizations?

      field :created_by, Gql::Types::UserType, description: 'User that created this record'
      field :updated_by, Gql::Types::UserType, description: 'Last user that updated this record'

      field :authorizations, [Gql::Types::AuthorizationType]

      field :firstname, String
      field :lastname, String
      field :fullname, String
      field :image, String
      field :image_source, String

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
      field :out_of_office_replacement, Gql::Types::UserType, description: 'Replacement agent if this user is out of office'

      field :personal_settings, Gql::Types::User::PersonalSettingsType, method: :preferences, description: 'Typed access to user preferences'
      field :preferences, GraphQL::Types::JSON, description: 'Direct access to preferences store'

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

    def secondary_organizations
      @object.organizations
    end

    def secondary_organizations?
      @object.organization_ids.present?
    end

    def created_by
      ::User.find_by(id: @object.created_by_id)
    end

    def updated_by
      ::User.find_by(id: @object.updated_by_id)
    end
  end
end
