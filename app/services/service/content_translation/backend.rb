# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::ContentTranslation::Backend
  # Resolves a provider name to the backend that answers for it. Only subclasses of Backend::Base
  # pass: the namespace will hold more than backends, and a name naming anything else must not be
  # taken for one.
  #
  # @param name [String, NilClass] a provider name, as stored in `content_translation_provider`
  # @return [Class, NilClass]
  def self.by_name(name)
    return if name.blank?

    klass = "Service::ContentTranslation::Backend::#{name.classify}".safe_constantize
    return if !klass.is_a?(Class) || !(klass < Service::ContentTranslation::Backend::Base)

    klass
  end

  # @return [Class, NilClass] the backend the admin configured, nil while none resolves
  def self.configured
    by_name(Setting.get('content_translation_provider'))
  end

  def self.configured?
    configured.present?
  end

  # The stored name of the active provider, read with a lock that lasts until the transaction ends.
  # A change of the active provider and the removal of a provider's config depend on each other:
  # both read it this way, so that one of two changes made at the same time sees the other.
  #
  # @return [String, NilClass]
  def self.locked_provider_name
    Setting.lock.find_by(name: 'content_translation_provider')&.state_current&.dig(:value)
  end

  # The backends that answer without an AI feature. They record their runs under the same identifier
  # as the AI backend, so whatever lists AI runs has to leave these out by name.
  def self.non_ai_backend_names
    [Service::ContentTranslation::Backend::DeepL, Service::ContentTranslation::Backend::LibreTranslate].map(&:backend_name)
  end
end
