# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The store of translations: one row per object and target locale, in the shared ai_stored_results
# table. It is the whole caching path of a backend without an AI feature behind it. That layer writes
# through .save as well, and reads with the key .lookup_attributes and .version build, so both key
# their rows the same way and neither serves what the other stored.
#
# The five keyword arguments of .find and .save are that key: which object, into which locale, of
# which content, and which service is asking.
class Service::ContentTranslation::StoredTranslation
  # Namespaces the rows in ai_stored_results, and doubles as the provider-routing key of
  # Service::AI::Feature::Translate.
  IDENTIFIER = 'translate'.freeze

  # The AI backend translates HTML in an intermediate format (ContentTranslation::Html). Changing it
  # is a new version, so translations of the previous format are not served anymore.
  AI_HTML_FORMAT = 'hybrid-1'.freeze

  # Where a row keeps the translations of the extra texts, in its metadata.
  EXTRA_TEXTS_KEY = 'extra_texts'.freeze

  class << self
    # The row of an object and target locale, whichever service produced it.
    def lookup_attributes(object, locale)
      {
        identifier:     IDENTIFIER,
        locale:,
        related_object: object,
      }
    end

    # A content digest instead of a timestamp, because an object can be touched without its content
    # changing. The producing service is part of it: the row itself is keyed without the service, so
    # the version is what makes another service's translation a miss instead of a reused result.
    def version(content, html, backend)
      Digest::SHA256.hexdigest("#{backend}\n#{content_format(html, backend)}\n#{content}")
    end

    # The part of .version that tells the kind of content apart, see
    # Service::AI::Feature::Translate.lookup_version_sql for its SQL counterpart.
    def content_format(html, backend)
      return html.to_s if !html || backend != Service::ContentTranslation::Backend::AI.backend_name

      AI_HTML_FORMAT
    end

    # @param object [ApplicationModel] the object whose content is translated
    # @param locale [Locale] the target locale
    # @param content [String] the content that is translated; it keys the row, so changed content
    #   misses instead of serving the translation of what the object said before
    # @param html [Boolean] whether that content is HTML
    # @param backend [String] `backend_name` of the service asking
    # @return [AI::StoredResult, NilClass] nil when that service has no translation of this content
    def find(object:, locale:, content:, html:, backend:)
      AI::StoredResult.find_by(**lookup_attributes(object, locale), version: version(content, html, backend))
    end

    # The translations a row holds of the given extra texts. The row is keyed by the content alone,
    # so each of them carries a digest of its own text: one that changed since has no translation,
    # and neither has one the row never held.
    #
    # @param record [AI::StoredResult]
    # @param extra_texts [Hash{Symbol => String}] the texts as they are now
    # @return [Hash{Symbol => String}]
    def extra_translations(record, extra_texts)
      stored = record.metadata[EXTRA_TEXTS_KEY].to_h

      extra_texts.each_with_object({}) do |(name, text), translations|
        entry = stored[name.to_s]

        translations[name] = entry['content'] if entry.is_a?(Hash) && entry['version'] == text_version(text)
      end
    end

    # @param translation [String] the translated content
    # @param extra_texts [Hash{Symbol => String}] plain texts translated along with the content
    # @param extra_translations [Hash{Symbol => String}] their translations, by the same names
    # @param metadata [Hash] what the producer reports about itself; the producing service is added
    #   here, so every row names it whatever wrote it.
    # @param analytics_run [AI::Analytics::Run, NilClass] nil for a backend that records none
    # @return [AI::StoredResult, NilClass]
    def save(object:, locale:, content:, html:, backend:, translation:, extra_texts: {}, extra_translations: {}, metadata: {}, analytics_run: nil)
      AI::StoredResult
        .find_or_initialize_by(**lookup_attributes(object, locale))
        .tap do |record|
          record.update!(
            version:          version(content, html, backend),
            metadata:         metadata.merge('backend' => backend).merge(extra_texts_metadata(extra_texts, extra_translations)),
            content:          translation,
            ai_analytics_run: analytics_run,
          )
        end
    # A backend that answers in place has no ContentTranslationJob lock in front of it, so two first
    # requests for the same object and locale can collide on the unique index - as a failed
    # validation when the other one committed first, as a database error when it commits in between.
    # The one that loses serves what the other stored, and nothing when the two translated different
    # content - it has its own translation to answer with either way.
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      find(object:, locale:, content:, html:, backend:)
    end

    private

    # Without a translated extra text the metadata holds nothing about them.
    def extra_texts_metadata(extra_texts, extra_translations)
      entries = extra_translations.compact_blank.to_h do |name, translation|
        [name.to_s, { 'version' => text_version(extra_texts[name]), 'content' => translation }]
      end

      entries.present? ? { EXTRA_TEXTS_KEY => entries } : {}
    end

    def text_version(text)
      Digest::SHA256.hexdigest(text.to_s)
    end
  end
end
