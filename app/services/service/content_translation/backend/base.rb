# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What a translation backend has to answer for the content translation services. A backend maps
# one translation service onto backend-neutral data; which one is used comes from the service config.
class Service::ContentTranslation::Backend::Base < Service::Base
  # Every failure of a translation service comes out as one of these, so a caller tells the
  # outcomes apart by class rather than by the wording the service answered with.
  class Error < StandardError; end

  class UnreachableError < Error
    def initialize(message = __('The translation service cannot be reached.'))
      super
    end
  end

  class InvalidCredentialsError < Error
    def initialize(message = __('The translation service refused the configured credentials.'))
      super
    end
  end

  class UnsupportedLanguageError < Error
    def initialize(message = __('The translation service does not support the requested target language.'))
      super
    end
  end

  class QuotaExceededError < Error
    def initialize(message = __('The quota or rate limit of the translation service is exhausted.'))
      super
    end
  end

  class ContentTooLargeError < Error
    def initialize(message = __('The content is too large for the translation service.'))
      super
    end
  end

  attr_reader :object, :content, :html, :locale, :persistence_strategy, :regeneration_of

  # Raises when the service behind this backend is not usable. Whether translation is switched on
  # at all is not its question - the content translation services ask that before.
  def self.ensure_enabled!
    nil
  end

  # Reaches the service with the config that would be stored, and proves the credentials it
  # carries are accepted. Raises one of the errors above. A backend without a testable endpoint
  # keeps the no-op, the way AI::Provider.ping! does.
  def self.ping!(_config)
    nil
  end

  # Whether producing a translation takes long enough to answer the caller later.
  def self.background?
    false
  end

  # The stable name stored with every translation this backend produces.
  def self.backend_name
    raise NotImplementedError
  end

  # Keys the service config must carry for this backend, beside `provider`.
  def self.required_config_keys
    []
  end

  # The locales this backend can translate into, out of the given active ones. Everything by
  # default; a service with a fixed language list narrows it down.
  #
  # @param locales [Array<Locale>]
  # @return [Array<Locale>]
  def self.supported_locales(locales)
    locales
  end

  def initialize(object:, content:, html:, locale:, persistence_strategy: :stored_or_request, regeneration_of: nil)
    @object               = object
    @content              = content
    @html                 = html
    @locale               = locale
    @persistence_strategy = persistence_strategy
    @regeneration_of      = regeneration_of
  end

  def backend_name
    self.class.backend_name
  end
end
