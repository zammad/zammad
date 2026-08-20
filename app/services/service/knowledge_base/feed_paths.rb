# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Builds the internal knowledge base feed paths offered to the current user, along
#   with the persistent token authenticating them (created on first use, like the
#   legacy feed dialog does). The category path covers the category including its
#   sub-categories and is only built while a category is being browsed.
#
#   Paths rather than absolute URLs: the frontend prefixes them with the configured
#   fqdn and falls back to the browser's origin while that is still the placeholder
#   default — the same rule the legacy feed dialog applied (App.Utils.baseUrl).
class Service::KnowledgeBase::FeedPaths < Service::Base
  requires_current_user!

  attr_reader :knowledge_base, :locale, :category, :renew

  # `locale` is the resolved KnowledgeBase::Locale the feeds should deliver.
  #   `renew` mints a new token, invalidating the URLs handed out so far.
  def initialize(knowledge_base:, locale:, category: nil, renew: false)
    @knowledge_base = knowledge_base
    @locale         = locale
    @category       = category
    @renew          = renew
  end

  def execute
    {
      knowledge_base_path: knowledge_base_path,
      category_path:       category_path,
    }
  end

  private

  def knowledge_base_path
    routes.feed_knowledge_base_path(knowledge_base, locale_code, token:)
  end

  def category_path
    return if category.nil?

    routes.feed_knowledge_base_category_path(knowledge_base, category, locale_code, token:)
  end

  def token
    @token ||= if renew
                 Token.renew_token!('KnowledgeBaseFeed', current_user.id, persistent: true)
               else
                 Token.ensure_token!('KnowledgeBaseFeed', current_user.id, persistent: true)
               end
  end

  def locale_code
    locale.system_locale.locale
  end

  def routes
    Rails.application.routes.url_helpers
  end
end
