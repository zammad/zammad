# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared by the connection dialog services, so validating, listing and resolving all work
# against the very same config that would be stored.
module Service::AI::ProviderConnection::Concerns::ResolvesEffectiveConfig
  extend ActiveSupport::Concern

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
