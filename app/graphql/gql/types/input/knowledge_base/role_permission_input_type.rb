# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase
  class RolePermissionInputType < Gql::Types::BaseInputObject
    description 'Represents the access one role is granted on a knowledge base object.'

    argument :role_id, GraphQL::Types::ID, description: 'Role the access applies to.'
    argument :access, Gql::Types::Enum::KnowledgeBase::PermissionAccessType, description: 'Access level to grant the role.'

    transform :load_role

    # Deliberately not `loads:`, like Gql::Types::Input::Ticket::LinkInputType is for its own
    #   reason: RolePolicy#show? only passes for an admin or for a role the user holds themselves,
    #   while granting knowledge base access is a knowledge_base.editor job that routinely names
    #   other roles. The role is only ever a key here, never data that is read back.
    def load_role(payload)
      payload.to_h.tap do |result|
        result[:role] = Gql::ZammadSchema.verified_object_from_id(result.delete(:role_id), type: ::Role)
      end
    end
  end
end
