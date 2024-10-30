# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class LinkObjectType < Gql::Types::BaseUnion
    description 'Linkable objects'
    possible_types Gql::Types::TicketType,
                   Gql::Types::KnowledgeBase::Answer::TranslationType
  end
end
