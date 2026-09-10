# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AI::Analytics
  class RunType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'AI::Analytics::Run identifies an AI result that can be used for analytics purposes.'

    field :related_object, Gql::Types::TicketType, null: true, description: 'The ticket related to this AI result.'

    # A result can be about something inside a ticket rather than about the ticket itself; the field
    #   promises the ticket, so an article is resolved to the one it belongs to now.
    def related_object
      case object.related_object
      when ::Ticket::Article
        object.related_object.ticket
      else
        object.related_object
      end
    end
  end
end
