# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Ticket::Article::TranslationResultType < Gql::Types::BaseObject
    description 'The outcome of translating one article of a ticket'

    field :article, Gql::Types::Ticket::ArticleType, null: false, description: 'The article the translation belongs to'
    field :translated, Boolean, null: true, description: 'True when translated, false when skipped, and null without a completed translation request'
    field :skip_reason, Gql::Types::Enum::Ticket::Article::TranslationSkipReasonType, null: true, description: 'Why the article was skipped, if it is one of the listed reasons'
    field :analytics, Gql::Types::AI::Analytics::MetadataType, null: true, description: 'Analytics metadata of the translation, if one is available'
  end
end
