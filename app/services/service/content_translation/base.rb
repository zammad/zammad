# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Translates the content of one object into a target locale. Everything that does not depend on
# the object lives here; a subclass only says which object it is and where its content comes from.
#
# Callers authorize: the mutation loads the object with its Pundit method, as the ticket summary
# does. Every object type has its own read rule, so this class validates the request only.
class Service::ContentTranslation::Base < Service::Base
  attr_reader :object, :target_locale, :source_language, :excluded_languages, :force, :background, :persistence_strategy, :regeneration_of

  Result = Struct.new(:content, :backend, :translated, :fresh, :analytics_run, :skip_reason, keyword_init: true)

  class InvalidTargetLocaleError < StandardError
    def initialize(target_locale)
      super(format(__("The locale '%s' is not active."), target_locale))
    end
  end

  class UnknownBackendError < StandardError
    def initialize
      super(__('The configured translation service is not available.'))
    end
  end

  # The subscription a deferred translation of this kind of object is published to.
  def self.subscription
    raise NotImplementedError
  end

  # @param object [ApplicationModel] the object whose content is translated; the translation is
  #   stored for it.
  # @param source_language [String, NilClass] language or locale code of the content; the object's
  #   own detection is used when nothing is given.
  # @param excluded_languages [Array<String>] languages, as Locale.language_of names them, whose
  #   content stays in the original.
  # @param force [Boolean] translate even when the source language matches the target or is
  #   excluded. Unrelated to the store: a stored translation is still served, use `regeneration_of`
  #   to bypass that.
  # @param background [Boolean, Symbol] :auto follows the backend preference; true always defers
  #   generation, false runs it in place. An explicit `persistence_strategy` overrides it.
  # @param persistence_strategy [Symbol, NilClass] @see Service::AI::Feature#initialize
  def initialize(object:, target_locale:, source_language: nil, excluded_languages: [], force: false, background: :auto, persistence_strategy: :stored_or_request, regeneration_of: nil)
    @object               = object
    @target_locale        = target_locale
    @source_language      = source_language
    @excluded_languages   = excluded_languages
    @force                = force
    @background           = background
    @persistence_strategy = persistence_strategy
    @regeneration_of      = regeneration_of
  end

  # @return [Result, NilClass] the translation; nil only when it was deferred to the background, or
  #   when the caller asked for a stored translation and there is none.
  def execute
    # Before the stored translation is looked up: a switched-off feature means nobody may
    # translate, not even what is stored. A switched-off service is different - what is stored is
    # the configured service's own translation, so it still counts - which is why #translate checks
    # that later.
    ensure_feature_enabled!

    locale # rejects an unknown or inactive target before any content is touched

    return untranslated_result if content.blank?
    return untranslated_result if same_language?
    return untranslated_result(skip_reason: 'excluded_language') if excluded_language?

    translate
  end

  private

  # A subclass adds the toggle of its own feature on top of the service-level one.
  def ensure_feature_enabled!
    Service::CheckFeatureEnabled.execute(name: 'content_translation_service', custom_error_message: __('No translation service is configured.'))
  end

  def content
    raise NotImplementedError
  end

  # @return [Boolean] whether the content is HTML rather than plain text
  def html?
    raise NotImplementedError
  end

  # @return [String, NilClass] language code of the content, nil if unknown
  def source_language_hint
    raise NotImplementedError
  end

  # The feature base silently falls back to a nil locale for an unknown code, which would collapse
  # every such translation of an object into one stored result - so resolve it here.
  def locale
    @locale ||= Locale.find_by(locale: target_locale, active: true) ||
                raise(InvalidTargetLocaleError, target_locale)
  end

  def same_language?
    return false if force || content_language.nil?

    content_language == Locale.language_of(locale.locale)
  end

  # Checked after #same_language?, so content in the target language is never reported as excluded.
  def excluded_language?
    return false if force || content_language.nil?

    excluded_languages.include?(content_language)
  end

  def content_language
    source = source_language.presence || source_language_hint

    Locale.language_of(source) if source.present?
  end

  # Nothing was translated - the content is empty, already in the target language, or excluded. The
  # caller still gets the content, so it has something to render.
  def untranslated_result(skip_reason: nil)
    Result.new(content: content.to_s, backend: nil, translated: false, fresh: false, analytics_run: nil, skip_reason:)
  end

  # A stored translation is the configured backend's own, and serving it does not need that service
  # to be usable; only producing a new one does, and only then may it be worth deferring - which is
  # the backend's own answer. The feature gate sits in #execute instead, see there.
  def translate
    stored = dispatch(:stored_only) if persistence_strategy != :request_only

    return stored if stored
    return        if persistence_strategy == :stored_only

    # Producing a translation needs the service to be usable; serving a stored one does not.
    backend_class.ensure_enabled!

    return defer_to_background if defer_to_background?

    dispatch(:request_only) || untranslated_result
  end

  def defer_to_background?
    # An explicit persistence strategy is the caller insisting on an answer of its own.
    return false if persistence_strategy != :stored_or_request

    background == :auto ? backend_class.background? : background
  end

  # The caller learns the outcome from the subscription the job triggers.
  def defer_to_background
    ContentTranslationJob.perform_later(object, target_locale, service: self.class.name, regeneration_of:)

    nil
  end

  def dispatch(strategy)
    data = backend_class.execute(
      object:,
      content:,
      html:                 html?,
      locale:,
      persistence_strategy: strategy,
      regeneration_of:,
    )

    return if data.blank?

    Result.new(translated: true, **data)
  end

  # A blank or unknown key is an error, not a fallback: the admin chose a service that is not there.
  def backend_class
    @backend_class ||= Service::ContentTranslation::Backend.configured || raise(UnknownBackendError)
  end
end
