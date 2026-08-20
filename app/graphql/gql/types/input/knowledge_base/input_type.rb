# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::KnowledgeBase
  class InputType < Gql::Types::BaseInputObject
    description 'Represents the knowledge base attributes to be used in update.'

    # Both texts live on the knowledge base's translation for one locale, which the mutation's
    #   `locale` names. Both are mandatory, so every call rewrites the whole translation for that
    #   locale rather than patching a single field of it.
    argument :title, Gql::Types::NonEmptyStringType, required: true, description: 'Title of the knowledge base in the locale of this mutation.'
    argument :footer_note, Gql::Types::NonEmptyStringType, required: true, description: 'Footer note of the knowledge base in the locale of this mutation.'

    argument :permissions, [Gql::Types::Input::KnowledgeBase::RolePermissionInputType], required: false, description: 'Granular access per role, applied in the same transaction as the knowledge base itself. Omitted leaves the stored permissions alone, an empty list drops all of them.'
  end
end
