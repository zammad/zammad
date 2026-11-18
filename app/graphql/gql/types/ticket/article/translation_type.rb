# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Ticket::Article::TranslationType < Gql::Types::ContentTranslationType
    description 'The translation of a ticket article'

    field :subject, String, null: true, description: 'The translated subject, if the article has one and it was translated along with the content'
  end
end
