# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer::Translation
  class ContentType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Answer Translation Content'

    field :body, String
    field :body_with_urls, String

    # What an editor has to load, which is *not* `body_with_urls` below: that one is rendered for
    #   reading - it resolves the answer-link markers into hrefs and expands the `(widget: video …)`
    #   markers into an `<iframe>`. Writing that back would store the rendered output in place of the
    #   markers, losing the video widget for good (and the `<iframe>` would not survive
    #   HtmlSanitizer.strict on the way in either).
    #
    # This is the model's own `body_with_urls`: the stored body with the inline images' `cid:`
    #   sources swapped for attachment URLs, so the editor can display them, and nothing else
    #   touched. HasRichText.insert_urls keeps the `cid` as an attribute, which is what
    #   HtmlSanitizer::CidToSrc turns back into `src="cid:…"` when it is saved - so the editor has to
    #   preserve that attribute (see the desktop editor's Image extension).
    field :body_for_editing, String, description: 'The stored body with inline image URLs resolved and nothing else rendered - what an editor loads, as opposed to `bodyWithUrls`', method: :body_with_urls
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
