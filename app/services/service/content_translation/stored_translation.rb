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

    # @param translation [String] the translated content
    # @param metadata [Hash] what the producer reports about itself; the producing service is added
    #   here, so every row names it whatever wrote it.
    # @param analytics_run [AI::Analytics::Run, NilClass] nil for a backend that records none
    # @return [AI::StoredResult, NilClass]
    def save(object:, locale:, content:, html:, backend:, translation:, metadata: {}, analytics_run: nil)
      AI::StoredResult
        .find_or_initialize_by(**lookup_attributes(object, locale))
        .tap do |record|
          record.update!(
            version:          version(content, html, backend),
            metadata:         metadata.merge('backend' => backend),
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
  end
end
