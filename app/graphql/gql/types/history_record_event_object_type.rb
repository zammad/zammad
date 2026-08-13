# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class HistoryRecordEventObjectType < Gql::Types::BaseUnion
    description 'History record event object'

    # Not extensible yet: the history fragments select on this union, so Apollo
    #   needs every member in its hardcoded 'possibleTypes' map (see
    #   shared/server/apollo/cache/initializer/history.ts) or it discards the
    #   fields of an unlisted type - which an addon cannot add without editing
    #   that core file.
    possible_types Gql::Types::UserType,
                   Gql::Types::GroupType,
                   Gql::Types::OrganizationType,
                   Gql::Types::TicketType,
                   Gql::Types::Ticket::ArticleType,
                   Gql::Types::MentionType,
                   Gql::Types::Ticket::SharedDraftZoomType,
                   Gql::Types::ChecklistType,
                   Gql::Types::Checklist::ItemType,
                   Gql::Types::ObjectClassType

    # Explicit type resolution is needed because of the pseudo
    # ObjectClassType.
    def self.resolve_type(object, _context)
      {
        ::Checklist               => Gql::Types::ChecklistType,
        ::Checklist::Item         => Gql::Types::Checklist::ItemType,
        ::Group                   => Gql::Types::GroupType,
        ::Mention                 => Gql::Types::MentionType,
        ::Organization            => Gql::Types::OrganizationType,
        ::Ticket                  => Gql::Types::TicketType,
        ::Ticket::Article         => Gql::Types::Ticket::ArticleType,
        ::Ticket::SharedDraftZoom => Gql::Types::Ticket::SharedDraftZoomType,
        ::User                    => Gql::Types::UserType
      }.fetch(object.class, Gql::Types::ObjectClassType)
    end
  end
end
