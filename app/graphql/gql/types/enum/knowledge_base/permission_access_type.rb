# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum::KnowledgeBase
  class PermissionAccessType < Gql::Types::Enum::BaseEnum
    description 'Access level a role has on a knowledge base object'

    # The values are the ones KnowledgeBase::Permission#access stores and
    #   KnowledgeBase::Permission#allowed_access validates against, so they map straight onto the
    #   model and onto what Service::KnowledgeBase::RolePermissions offers the form.
    value 'editor', 'May read and edit the content.', value: 'editor'
    value 'reader', 'May read the content, including internally published answers.', value: 'reader'
    value 'none', 'Has no access at all.', value: 'none'
  end
end
