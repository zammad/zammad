# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Ticket::Article::TranslationType < Gql::Types::BaseObject
    description 'The translation of one article of a ticket'

    field :article, Gql::Types::Ticket::ArticleType, null: false, description: 'The article the translation belongs to'
    field :translation, Gql::Types::ContentTranslationType, null: false, description: 'The translation'
  end
end
