# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Masks secret values in a model's JSON `config` column on asset serialization, following
# Zammad's house pattern (Channel::SENSITIVE_FIELDS / ExternalCredential::SensitiveAttributes).
module CanMaskConfigSecrets
  extend ActiveSupport::Concern

  include CanSensitiveAssets

  # Matched as substrings, so e.g. `api_key`, `client_secret`, `app_secret` are covered.
  SENSITIVE_CONFIG_KEYS = %w[token api_key secret password].freeze

  # The dotted `config.*` paths whose keys look secret. Module function so controllers can
  # run the same check outside a model callback. Handles both a string-keyed Hash and
  # ActionController::Parameters.
  def self.sensitive_config_attributes(object_payload)
    (object_payload[:config].try(:keys) || object_payload['config'].try(:keys) || [])
      .select { |key| SENSITIVE_CONFIG_KEYS.any? { |secret| key.to_s.include?(secret) } } # rubocop:disable Style/ArrayIntersect -- substring match on key names, not array intersection
      .map    { |key| "config.#{key}" }
  end

  def sensitive_attributes(object_payload, _object)
    CanMaskConfigSecrets.sensitive_config_attributes(object_payload)
  end

end
