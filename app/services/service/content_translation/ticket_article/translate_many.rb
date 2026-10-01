# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::ContentTranslation::TicketArticle::TranslateMany < Service::Base
  requires_current_user!

  attr_reader :articles, :target_locale, :generate_missing

  # @param articles [Array<Ticket::Article>] the articles to translate
  # @param target_locale [String] e.g. "de-de"
  def initialize(articles:, target_locale:, generate_missing: false)
    @articles         = articles
    @target_locale    = target_locale
    @generate_missing = generate_missing
  end

  # Only attempted translations include :translation; nil means the result is pending. A lookup
  # attempts none, and marks the articles whose translation someone else started with :pending.
  def execute
    Service::CheckFeatureEnabled.execute(name: 'content_translation_service')
    Service::CheckFeatureEnabled.execute(name: 'content_translation_ticket_article')
    return lookup if !generate_missing

    Service::ContentTranslation::TicketArticle::CheckAutoAllowed.execute(user: current_user)

    articles.map do |article|
      next { article: } if !translatable?(article)

      { article:, translation: translate(article) }
    end
  end

  private

  def lookup
    in_progress = Service::ContentTranslation::InProgress.execute(objects: articles, target_locale:).to_set

    articles.map do |article|
      in_progress.include?(article) ? { article:, pending: true } : { article: }
    end
  end

  def translatable?(article)
    return false if article.preferences[:delivery_message]

    article.sender.name != 'System' || article.type.name == 'note'
  end

  # Articles created while detection was on keep their language, so the setting decides.
  def excluded_languages
    @excluded_languages ||= if Setting.get('language_detection_article').blank?
                              []
                            else
                              current_user.preferences.fetch('content_translation_excluded_languages', [])
                            end
  end

  # Unforced, so an article already in the target language or in an excluded one is not sent to the
  # service: the agent asked for the ticket, not for this one article.
  #
  # No batch lookup of the stored translations in front of this loop: a stored translation is
  # served with its content, which such a lookup would have to read a second time anyway.
  def translate(article)
    Service::ContentTranslation::TicketArticle.execute(object: article, target_locale:, excluded_languages:, force: false, background: true)
  end
end
