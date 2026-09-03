# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class TranslationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Translation'

    # The texts of one locale, which is what a translation owns. What the knowledge base *shows* in
    #   a locale (`isVisiblePublicly`) stays on the knowledge base, for the reason it stays on a
    #   category: it describes the content of the browsed locale, which this translation may not be.
    field :title, String, null: false
    field :footer_note, String

    def self.pundit_object(object)
      object.knowledge_base
    end

    # Readable wherever the knowledge base itself is - it exposes nothing beyond its texts, and
    #   KnowledgeBaseType uses the same check.
    def self.nested_access_pundit_method
      :show_any?
    end

    def self.direct_access_pundit_method
      :show_any?
    end
  end
end
