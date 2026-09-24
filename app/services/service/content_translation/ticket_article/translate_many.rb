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

  # Only attempted translations include :translation; nil means the result is pending.
  def execute
    Service::CheckFeatureEnabled.execute(name: 'content_translation_service')
    Service::CheckFeatureEnabled.execute(name: 'content_translation_ticket_article')
    ensure_allowed! if generate_missing

    articles.map do |article|
      next { article: } if !generate_missing || !translatable?(article)

      { article:, translation: translate(article) }
    end
  end

  private

  def translatable?(article)
    return false if article.preferences[:delivery_message]

    article.sender.name != 'System' || article.type.name == 'note'
  end

  def ensure_allowed!
    return if Service::ContentTranslation::TicketArticle::AutoAllowed.execute(user: current_user)

    raise Exceptions::Forbidden, __('Automatic translation of ticket articles is not available for you.')
  end

  # Unforced, so an article already in the target language is not sent to the service: the agent
  # asked for the ticket, not for this one article.
  #
  # No batch lookup of the stored translations in front of this loop: a stored translation is
  # served with its content, which such a lookup would have to read a second time anyway.
  def translate(article)
    Service::ContentTranslation::TicketArticle.execute(object: article, target_locale:, force: false, background: true)
  end
end
