# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Ticket::Article::TranslationResultType < Gql::Types::BaseObject
    description 'The outcome of translating one article of a ticket'

    field :article, Gql::Types::Ticket::ArticleType, null: false, description: 'The article the translation belongs to'
    field :translated, Boolean, null: true, description: 'True when translated, false when skipped, and null without a completed translation request'
    field :analytics, Gql::Types::AI::Analytics::MetadataType, null: true, description: 'Analytics metadata of the translation, if one is available'
  end
end
