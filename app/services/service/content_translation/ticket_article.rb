# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::ContentTranslation::TicketArticle < Service::ContentTranslation::Base
  def self.subscription
    Gql::Subscriptions::Ticket::Article::TranslationUpdates
  end

  # The stored translations of many articles at once, for a list. Only translations of the current
  #   content count, as when a single article is translated - the content digest is compared in
  #   SQL, so no body has to be loaded for it.
  #
  # @param articles [Array<Ticket::Article>, ActiveRecord::Relation]
  # @param target_locale [String]
  # @return [ActiveRecord::Relation<AI::StoredResult>] empty for an unknown or inactive locale
  def self.stored_translations(articles, target_locale)
    locale = Locale.find_by(locale: target_locale, active: true)
    return AI::StoredResult.none if locale.nil?

    AI::StoredResult
      .select(%i[id related_object_id metadata])
      .joins('INNER JOIN ticket_articles ON ticket_articles.id = ai_stored_results.related_object_id')
      .where(
        identifier:          Service::AI::Feature::Translate.identifier,
        locale:,
        related_object_type: 'Ticket::Article',
        related_object_id:   articles.map(&:id),
      )
      .where("ai_stored_results.version = #{version_sql}")
  end

  # Only the configured backend's own translations count, like in a single lookup - the version of
  # a row of another backend does not match.
  def self.version_sql
    Service::AI::Feature::Translate.lookup_version_sql(
      Service::ContentTranslation::Backend.configured&.backend_name,
      "ticket_articles.content_type ILIKE '%html%'",
      'ticket_articles.body',
    )
  end
  private_class_method :version_sql

  # The translation as the client renders it: inline image references resolved like in the
  #   article's own display body. The article is not touched.
  #
  # @param article [Ticket::Article]
  # @param translation [Result, Hash, nil] as produced by this service, or as published by the job
  # @return [Hash, nil] `content`, `backend` and `translated`; nil stays nil, a missing translation
  #   must not turn into an empty one
  def self.for_display(article, translation)
    return if translation.nil?

    data = translation.to_h.symbolize_keys.slice(:content, :backend, :translated)

    return data if data[:content].blank?

    data.merge(content: article.class.insert_urls(article, data[:content]).first)
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
