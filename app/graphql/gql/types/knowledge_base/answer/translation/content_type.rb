# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer::Translation
  class ContentType < Gql::Types::BaseObject
    include Gql::Concerns::IsModelObject
    include Gql::Concerns::HasPunditAuthorization
    include KnowledgeBaseRichTextHelper

    description 'Knowledge Base Answer Translation Content'

    field :body, String
    field :body_prepared, String
    field :has_attachments, Boolean, null: false, method: :attachments?

    def body_prepared
      return object.body_with_urls if object.body.exclude?('data-target-type')

      prepare_rich_text_links(object.body_with_urls)
    end

    def attachments?
      object.attachments.any?
    end
  end
end
