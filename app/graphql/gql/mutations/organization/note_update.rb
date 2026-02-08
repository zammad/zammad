# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Organization::NoteUpdate < BaseMutation
    description 'Update the note field of an organization.'

    argument :id, GraphQL::Types::ID, description: 'The organization ID', as: :current_organization, loads: Gql::Types::OrganizationType
    argument :note, String, description: 'The organization note'

    field :organization, Gql::Types::OrganizationType, description: 'The updated organization.'

    requires_permission 'admin.organization', 'ticket.agent'

    def resolve(current_organization:, note:)
      { organization: forced_update(current_organization:, note:) }
    end

    private

    def forced_update(current_organization:, note:)
      current_organization.with_lock do
        current_organization.update!({ note: })
      end

      current_organization
    end
  end
end
