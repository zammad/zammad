# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::Article
  class SenderType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Ticket article senders'

    field :name, Gql::Types::Enum::TicketArticleSenderNameType
  end
end
