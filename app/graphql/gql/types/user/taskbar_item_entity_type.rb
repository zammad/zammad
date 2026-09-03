# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User
  class TaskbarItemEntityType < Gql::Types::BaseUnion
    description 'Objects representing taskbar item entity'
    possible_types Gql::Types::UserType,
                   Gql::Types::OrganizationType,
                   Gql::Types::TicketType,
                   # An answer edit tab is a tab of one *translation* - the locale is the qualifier
                   #   in its key - so that is what it renders, resolved for its own locale (see
                   #   Gql::Types::User::TaskbarItemType#object_entity!). The answer itself would
                   #   be one object shared by every locale's tab, leaving a client that caches by
                   #   object identity one title for all of them.
                   Gql::Types::KnowledgeBase::Answer::TranslationType,
                   Gql::Types::User::TaskbarItemEntity::TicketCreateType,
                   Gql::Types::User::TaskbarItemEntity::KnowledgeBaseAnswerCreateType,
                   Gql::Types::User::TaskbarItemEntity::SearchType,
                   *extension_types

    def self.resolve_type(obj, _context)
      return super if !obj.is_a?(Hash)

      raise GraphQL::RequiredImplementationMissingError, 'Cannot resolve type, missing required ":type" key in hash.' if obj[:type].blank? # rubocop:disable Zammad/DetectTranslatableString

      "Gql::Types::User::TaskbarItemEntity::#{obj[:type]}Type".constantize
    end
  end
end
