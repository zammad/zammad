# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Organization::Update < BaseMutation
    description 'Update organization data.'

    argument :id, GraphQL::Types::ID, required: true, description: 'The organization ID', as: :current_organization, loads: Gql::Types::OrganizationType
    argument :input, Gql::Types::Input::OrganizationInputType, required: true, description: 'The organization data'

    field :organization, Gql::Types::OrganizationType, null: false, description: 'The updated organization.'

    def load_id(id:)
      Gql::ZammadSchema.verified_object_from_id(id, type: ::Organization)
    end

    # TODO/FIXME: Remove this again when we have a proper solution to deal with Pundit stuff in GraphQL mutations.
    def self.authorize(_obj, ctx)
      ctx[:current_user].permissions?(['admin.organization', 'ticket.agent'])
    end

    def resolve(current_organization:, input:)
      { organization: update(current_organization, input) }
    end

    private

    def update(current_organization, input)
      params = input.to_h

      convert_object_attribute_values(params)
      set_core_workflow_information(params, current_organization, 'update')

      current_organization.with_lock do
        current_organization.update!(params)
      end

      current_organization
    end
  end
end
