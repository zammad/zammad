# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer::Translation
  class ContentType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Answer Translation Content'

    field :body, String
    field :body_with_urls, String
    field :body_excerpt, String, description: 'Short plain-text excerpt of the body (~50 words, cut on sentence boundaries).'
    field :has_attachments, Boolean, null: false, resolver_method: :attachments?

    # Links to other answers point at the desktop app's own answer route (not the public help
    #   page): the reader here is an agent, who stays in the app when following one.
    def body_with_urls
      KnowledgeBaseRichText.prepare(object.body_with_urls, &:desktop_url)
    end

    def attachments?
      object.attachments.any?
    end
  end
end
