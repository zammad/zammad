# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class ActivityMessageMetaObjectType < BaseUnion
    description 'Objects used to build activity message'
    possible_types Gql::Types::UserType, Gql::Types::OrganizationType,
                   Gql::Types::DataPrivacyTaskType, Gql::Types::GroupType, Gql::Types::RoleType,
                   Gql::Types::TicketType, Gql::Types::Ticket::ArticleType,
                   Gql::Types::OnlineNotificationStandaloneType,
                   Gql::Types::KnowledgeBase::Answer::TranslationType
  end
end
