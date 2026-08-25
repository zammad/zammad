# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class KnowledgeBase < BaseQuery
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Fetch the active knowledge base for browsing (landing + language selector)'

    argument :locale, String, required: false, description: 'System locale code used to resolve titles'

    type Gql::Types::KnowledgeBaseType, null: true

    def resolve(locale: nil)
      # Only the active knowledge base is browsable — without one there is nothing to browse at
      #   all, which is an error like it is for its content.
      knowledge_base = ::KnowledgeBase.active.first!

      store_knowledge_base_locale(knowledge_base, locale)

      knowledge_base
    end
  end
end
