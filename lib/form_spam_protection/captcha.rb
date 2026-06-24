# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Base class and registry for the form channel's CAPTCHA providers. Concrete
# providers live under form_spam_protection/captcha/ (loaded automatically via
# Mixin::RequiredSubPaths) and are discovered through the inheritance tree, so a
# new provider only needs to subclass this and declare a key/title — no central
# list to maintain. Siteverify-style providers additionally include
# Concerns::TokenVerification for the shared HTTP verification flow.
class FormSpamProtection::Captcha
  include Mixin::RequiredSubPaths

  # @return [String, nil] stable identifier and setting value; concrete providers override this.
  def self.key; end

  # @return [String, nil] human-readable name for the admin UI; concrete providers override this.
  def self.title; end

  # @return [Array<Class>] all selectable provider classes (abstract bases excluded).
  def self.providers
    descendants.select { |klass| klass.key.present? }
  end

  # @return [Class, nil]
  def self.by_key(key)
    return if key.blank?

    providers.find { |klass| klass.key == key }
  end

  # @return [FormSpamProtection::Captcha, nil] instance of the configured provider.
  def self.configured_provider
    by_key(Setting.get('form_ticket_create_captcha_provider'))&.new
  end

  # @return [Hash] secret-free configuration for the embeddable form widget.
  def frontend_config
    { provider: self.class.key }.merge(widget_config)
  end

  # @param submission [FormSpamProtection::Submission]
  #
  # @return [Boolean]
  def verify(submission)
    raise NotImplementedError
  end

  # Providers that issue a server-side challenge (e.g. self-hosted proof-of-work)
  # override this; it is served via the form captcha-challenge endpoint. Providers
  # whose challenges come from their own service return nil.
  #
  # @return [Hash, nil]
  def challenge
    nil
  end

  private

  def widget_config
    {}
  end

  def options
    @options ||= (Setting.get('form_ticket_create_captcha_options') || {}).with_indifferent_access
  end

  def site_key
    # Stored as `sitekey` (not `site_key`): the public site key is not a secret, but
    # a `_key` suffix would trip the settings masking and hide it from the admin.
    options[:sitekey]
  end

  def secret
    options[:secret]
  end
end
