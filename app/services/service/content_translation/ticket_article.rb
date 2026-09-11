# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::ContentTranslation::TicketArticle < Service::ContentTranslation::Base
  def self.subscription
    Gql::Subscriptions::Ticket::Article::TranslationUpdates
  end

  private

  def ensure_feature_enabled!
    super

    Service::CheckFeatureEnabled.execute(name: 'content_translation_ticket_article', custom_error_message: __('Ticket article translation is not enabled.'))
  end

  def content
    object.body
  end

  def html?
    object.content_type.match?(%r{html}i)
  end

  # Set on create by the opt-in article language detection, so it is often unknown.
  def source_language_hint
    object.detected_language
  end
end
