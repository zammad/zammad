# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User
  class TaskbarItemEntityType < Gql::Types::BaseUnion
    description 'Objects representing taskbar item entity'
    possible_types Gql::Types::UserType,
                   Gql::Types::OrganizationType,
                   Gql::Types::TicketType,
                   Gql::Types::User::TaskbarItemEntity::TicketCreateType,
                   Gql::Types::User::TaskbarItemEntity::SearchType

    def self.resolve_type(obj, _context)
      return super if !obj.is_a?(Hash)

      raise GraphQL::RequiredImplementationMissingError, 'Cannot resolve type, missing required ":type" key in hash.' if obj[:type].blank? # rubocop:disable Zammad/DetectTranslatableString

      "Gql::Types::User::TaskbarItemEntity::#{obj[:type]}Type".constantize
    end
  end
end
