# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::ContentTranslation::Backend
  # Resolves the key stored in the service config to the backend that answers for it. Only
  # subclasses of Backend::Base pass: the namespace will hold more than backends, and a key naming
  # anything else must not be taken for one.
  #
  # @param name [String, NilClass] the `provider` key of `content_translation_service_config`
  # @return [Class, NilClass]
  def self.by_name(name)
    return if name.blank?

    klass = "Service::ContentTranslation::Backend::#{name.classify}".safe_constantize
    return if !klass.is_a?(Class) || !(klass < Service::ContentTranslation::Backend::Base)

    klass
  end

  # @return [Class, NilClass] the backend the admin configured, nil while none resolves
  def self.configured
    by_name(Setting.get('content_translation_service_config').to_h.with_indifferent_access[:provider])
  end

  def self.configured?
    configured.present?
  end
end
