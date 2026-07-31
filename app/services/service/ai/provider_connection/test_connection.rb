# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Validates that a provider endpoint is reachable with the credentials that would be stored,
# and detects whether the configured model accepts the temperature parameter.
class Service::AI::ProviderConnection::TestConnection < Service::Base
  attr_reader :provider, :incoming_config, :existing_config, :related_object

  # incoming_config may contain mask sentinels (restored from existing_config);
  # nil means no config was submitted, so the stored config is validated.
  #
  # related_object is the connection being edited, so its HTTP logs can be attributed to it. It is
  # nil while a connection is created, because the record does not exist yet.
  def initialize(provider:, incoming_config: nil, existing_config: {}, related_object: nil)
    @provider        = provider
    @incoming_config = incoming_config
    @existing_config = existing_config.to_h
    @related_object  = related_object
  end

  # @return [Boolean] whether the configured model supports the temperature parameter
  def execute
    klass = AI::Provider.by_name(provider)
    raise Exceptions::UnprocessableContent, __('Unknown provider') if klass.nil?

    config = effective_config
    klass.ping!(config, related_object:)
    klass.check_temperature_support!(config, related_object:)
  end

  private

  # The config exactly as it will be stored: mask sentinels restored, blank strings dropped
  # (mirrors AI::ProviderConnection#remove_blank_config_values).
  def effective_config
    return existing_config.deep_symbolize_keys if incoming_config.nil?

    incoming_config
      .to_h { |key, value| [key, value == SensitiveParamsHelper::SENSITIVE_MASK ? existing_config[key] : value] }
      .reject { |_k, v| v.is_a?(String) && v.blank? }
      .deep_symbolize_keys
  end
end
