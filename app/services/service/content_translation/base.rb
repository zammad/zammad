# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Translates the content of one object into a target locale. Everything that does not depend on
# the object lives here; a subclass only says which object it is and where its content comes from.
#
# Callers authorize: the mutation loads the object with its Pundit method, as the ticket summary
# does. Every object type has its own read rule, so this class validates the request only.
class Service::ContentTranslation::Base < Service::Base
  attr_reader :object, :target_locale, :source_language, :force, :background, :persistence_strategy, :regeneration_of

  Result = Struct.new(:content, :backend, :translated, :fresh, :analytics_run, keyword_init: true)

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
  # @param force [Boolean] translate even when the source language matches the target. Unrelated to
  #   the store: a stored translation is still served, use `regeneration_of` to bypass that.
  # @param background [Boolean] set it to false when the caller cannot be answered later - the
  #   background job does, because it is the background. Whether deferring is worth it at all is
  #   the translation service's own answer, and an explicit `persistence_strategy` overrides it.
  # @param persistence_strategy [Symbol, NilClass] @see Service::AI::Feature#initialize
  def initialize(object:, target_locale:, source_language: nil, force: false, background: true, persistence_strategy: :stored_or_request, regeneration_of: nil)
    @object               = object
    @target_locale        = target_locale
    @source_language      = source_language
    @force                = force
    @background           = background
    @persistence_strategy = persistence_strategy
    @regeneration_of      = regeneration_of
  end

  # @return [Result, NilClass] the translation; nil only when it was deferred to the background, or
  #   when the caller asked for a stored translation and there is none.
  def execute
    # Before the stored translation is looked up: a switched-off feature means nobody may
    # translate, not even what is stored. A switched-off service is different - translations are
    # reused across services, so a stored one still counts - which is why #translate checks that later.
    ensure_feature_enabled!

    locale # rejects an unknown or inactive target before any content is touched

    return untranslated_result if content.blank?
    return untranslated_result if same_language?

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
    return false if force

    source = source_language.presence || source_language_hint

    return false if source.blank?
    return false if primary_language(source) != primary_language(locale.locale)

    script(source) == script(locale.locale)
  end

  def primary_language(code)
    code.to_s.split('-').first
  end

  # Locales of one language can differ by writing system rather than by region (Chinese, Serbian),
  # and a source language often names no script at all - CLDR fills in the likely one, so
  # Simplified content is not taken for Traditional.
  def script(code)
    TwitterCldr::Shared::Locale.parse(code).maximize.script
  rescue
    nil
  end

  # Nothing was translated - the content is empty, or it is already in the target language. The
  # caller still gets the content, so it has something to render.
  def untranslated_result
    Result.new(content: content.to_s, backend: nil, translated: false, fresh: false, analytics_run: nil)
  end

  # A stored translation is served whatever the backend is; only producing a new one needs the
  # translation service to be usable, and only then may it be worth deferring - which is the
  # backend's own answer. The feature gate sits in #execute instead, see there.
  def translate
    stored = dispatch(:stored_only) if persistence_strategy != :request_only

    return stored if stored
    return        if persistence_strategy == :stored_only

    # Producing a translation needs the service to be usable; serving a stored one does not.
    backend_class.ensure_enabled!

    return defer_to_background if defer_to_background?

    dispatch(:request_only)
  end

  def defer_to_background?
    # An explicit persistence strategy is the caller insisting on an answer of its own.
    return false if persistence_strategy != :stored_or_request

    background && backend_class.background?
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
