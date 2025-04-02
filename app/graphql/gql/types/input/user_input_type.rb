# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class UserInputType < Gql::Types::BaseInputObject
    include Gql::Types::Input::Concerns::ProvidesObjectAttributeValues

    description 'The user add/update fields.'

    argument :firstname, String, required: false, description: 'The user first name'
    argument :lastname, String, required: false, description: 'The user last name'
    argument :email, String, required: false, description: 'The user email'
    argument :password, String, required: false, description: 'The user password'
    argument :organization_id, GraphQL::Types::ID, required: false, description: 'The organization the user belongs to',
      loads: Gql::Types::OrganizationType
    argument :organization_ids, [GraphQL::Types::ID], required: false, description: 'The secondary organizations the user belongs to',
      loads: Gql::Types::OrganizationType
    argument :role_ids, [GraphQL::Types::ID], required: false, description: 'The roles (e.g. admin, agent, (e.g. Agent or Customer) this user has',
      loads: Gql::Types::RoleType
    argument :web, String, required: false, description: 'The user web'
    argument :phone, String, required: false, description: 'The user phone'
    argument :mobile, String, required: false, description: 'The user mobile'
    argument :fax, String, required: false, description: 'The user fax'
    argument :vip, Boolean, required: false, description: 'The user vip flag'
    argument :active, Boolean, required: false, description: 'The user active flag'
    argument :note, String, required: false, description: 'The user note'

    argument :group_ids, [User::GroupPermissionEntryType], required: false, description: 'User group access levels'

    transform :transform_group_access_map

    def transform_group_access_map(payload)
      payload
        .to_h
        .tap do |result|
          result[:group_ids_access_map] = result
            .delete(:group_ids)
            &.each_with_object({}) do |elem, memo|
              memo[elem[:group_internal_id]] = elem[:access_type]
            end
        end
    end
  end

end
