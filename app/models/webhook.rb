# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Webhook < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasCollectionUpdate
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include EnsuresNoRelatedObjects
  include CanSensitiveAssets

  SENSITIVE_FIELDS = %i[bearer_token signature_token basic_auth_password].freeze

  before_save :reset_custom_payload

  validates :name, presence: true
  validate :validate_endpoint
  validate :validate_custom_payload
  validate :validate_http_method

  validates :note, length: { maximum: 500 }
  sanitized_html :note

  store :preferences

  ensures_no_related_objects_path 'notification.webhook', 'webhook_id'

  HTTP_METHODS = %w[post put patch delete].freeze

  private

  def reset_custom_payload
    return true if customized_payload

    self.custom_payload = nil

    true
  end

  def validate_endpoint
    # Replace placeholders with dummy values for validation
    endpoint_for_validation = endpoint&.gsub(%r{#\{[a-z0-9_.?!]+\}}, '__PLACEHOLDER__')
    uri = URI.parse(endpoint_for_validation)

    errors.add(:endpoint, __('The provided endpoint is invalid, no http or https protocol was specified.')) if !uri.is_a?(URI::HTTP)
    errors.add(:endpoint, __('The provided endpoint is invalid, no hostname was specified.')) if uri.host.blank?

    HostnameSafetyCheck.validate!(uri.hostname, allow_private: true, allow_loopback: true)
  rescue URI::InvalidURIError
    errors.add :endpoint, __('The provided endpoint is invalid.')
  rescue HostnameSafetyCheck::LoopbackIpError
    errors.add :endpoint, __('The provided endpoint is invalid, it points to a loopback IP address.')
  rescue HostnameSafetyCheck::LinkLocalIpError
    errors.add :endpoint, __('The provided endpoint is invalid, it points to a link-local IP address.')
  rescue HostnameSafetyCheck::SafetyError
    errors.add :endpoint, __('The provided endpoint is invalid, it could not be resolved to a safe IP address.')
  end

  def validate_custom_payload
    return true if custom_payload.blank?

    begin
      JSON.parse(custom_payload)
    rescue
      errors.add :custom_payload, __('The provided payload is invalid. Please check your syntax.')
    end

    true
  end

  def validate_http_method
    return true if http_method.blank?

    return true if HTTP_METHODS.include?(http_method.downcase)

    errors.add :http_method, __('The provided HTTP method is invalid.')
  end
end
