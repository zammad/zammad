# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Types
  class UserType < Gql::Types::BaseObject
    include Gql::Concern::IsModelObject

    def self.authorize(object, ctx)
      Pundit.authorize ctx[:current_user], object, :show?
    end

    description 'Users (admins, agents and customers)'

    implements Gql::Types::ObjectAttributeValueInterface

    field :organization, Gql::Types::OrganizationType, null: true
    field :login, String, null: false
    field :firstname, String, null: true
    field :lastname, String, null: true
    field :email, String, null: true
    field :image, String, null: true
    field :image_source, String, null: true
    field :web, String, null: true
    field :password, String, null: true
    field :phone, String, null: true
    field :fax, String, null: true
    field :mobile, String, null: true

    # These fields are changeable object attributes, so manage them only via the ObjectAttributeInterface
    # field :department, String, null: true
    # field :street, String, null: true
    # field :zip, String, null: true
    # field :city, String, null: true
    # field :country, String, null: true
    # field :address, String, null: true

    field :vip, Boolean, null: true
    field :verified, Boolean, null: false
    field :active, Boolean, null: false
    field :note, String, null: true
    field :last_login, GraphQL::Types::ISO8601DateTime, null: true
    field :source, String, null: true
    field :login_failed, Integer, null: false
    field :out_of_office, Boolean, null: false
    field :out_of_office_start_at, GraphQL::Types::ISO8601Date, null: true
    field :out_of_office_end_at, GraphQL::Types::ISO8601Date, null: true
    field :out_of_office_replacement_id, Integer, null: true
    field :preferences, GraphQL::Types::JSON, null: true
  end
end
