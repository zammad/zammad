# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer::Translation
  class ContentType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization
    include KnowledgeBaseRichTextHelper

    description 'Knowledge Base Answer Translation Content'

    field :body, String
    field :body_prepared, String
    field :has_attachments, Boolean, null: false, resolver_method: :attachments?

    def body_prepared
      prepare_rich_text(object.body_with_urls)
    end

    def attachments?
      object.attachments.any?
    end
  end
end
