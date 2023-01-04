# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class UserInputType < Gql::Types::BaseInputObject
    include Gql::Types::Input::Concerns::ProvidesObjectAttributeValues

    description 'The user add/update fields.'

    argument :firstname, String, required: false, description: 'The user first name'
    argument :lastname, String, required: false, description: 'The user last name'
    argument :email, String, description: 'The user email'
    argument :password, String, required: false, description: 'The user password'
    argument :organization_id, GraphQL::Types::ID, required: false, description: 'The organization the user belongs to', loads: Gql::Types::OrganizationType
    argument :web, String, required: false, description: 'The user web'
    argument :phone, String, required: false, description: 'The user phone'
    argument :mobile, String, required: false, description: 'The user mobile'
    argument :fax, String, required: false, description: 'The user fax'
    argument :vip, Boolean, required: false, description: 'The user vip flag'
    argument :active, Boolean, required: false, description: 'The user active flag'
    argument :note, String, required: false, description: 'The user note'
  end
end
