# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared by the knowledge base feed query and the token renewal: both answer with
#   the feed paths of the browsed node, and only the token behind them differs.
module Gql::Concerns::HandlesKnowledgeBaseFeed
  extend ActiveSupport::Concern

  included do
    include Gql::Concerns::HandlesKnowledgeBaseLocale
  end

  private

  # `renew` mints a new access token first, which invalidates the URLs handed out
  #   so far.
  def knowledge_base_feed_paths(category:, locale:, renew: false)
    # Only the active knowledge base is browsable, so only it has feeds to offer —
    #   asking without one is an error, like it is for its answers.
    knowledge_base = ::KnowledgeBase.active.first!

    store_knowledge_base_locale(knowledge_base, locale)

    # Unlike the browsing queries, no additional locale check on the category:
    #   the feed endpoint authorizes it locale-agnostically (`show_any?`), which
    #   is exactly what the argument's Pundit gate already applied.
    ::Service::KnowledgeBase::FeedPaths
      .with_current_user(context.current_user)
      .execute(knowledge_base:, category:, locale: context[:knowledge_base_locale], renew:)
  end
end
