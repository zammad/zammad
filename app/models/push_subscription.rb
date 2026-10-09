# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# One Web Push subscription of one browser on one device, see RFC 8030.
class PushSubscription < ApplicationModel
  # Uncompressed P-256 public key and the authentication secret, see RFC 8291.
  P256DH_BYTES = 65
  AUTH_BYTES   = 16

  # Browsers only hand out endpoints of their vendor's push service. Accepting
  #   nothing else keeps the server from sending requests to arbitrary hosts.
  PUSH_SERVICE_DOMAINS = %w[
    web.push.apple.com
    fcm.googleapis.com
    jmt17.google.com
    push.services.mozilla.com
    notify.windows.com
  ].freeze

  belongs_to :user

  validates :endpoint, presence: true, uniqueness: { case_sensitive: true }, length: { maximum: 2000 }
  validates :p256dh,   presence: true, length: { maximum: 200 }
  validates :auth,     presence: true, length: { maximum: 100 }

  validate :endpoint_is_https_url
  validate :endpoint_is_known_push_service
  validate :keys_are_valid

  def known_push_service?
    host = URI.parse(endpoint.to_s).host.to_s.downcase.delete_suffix('.')

    PUSH_SERVICE_DOMAINS.any? { |domain| host == domain || host.end_with?(".#{domain}") }
  rescue URI::InvalidURIError
    false
  end

  private

  # Push resources have to be reachable via TLS (RFC 8030), and the server
  #   connects to whatever is stored here.
  def endpoint_is_https_url
    return if endpoint.blank?

    uri = URI.parse(endpoint)
    return if uri.is_a?(URI::HTTPS) && uri.host.present?

    errors.add(:endpoint, __('is not an HTTPS URL'))
  rescue URI::InvalidURIError
    errors.add(:endpoint, __('is not an HTTPS URL'))
  end

  def endpoint_is_known_push_service
    return if endpoint.blank? || known_push_service?

    errors.add(:endpoint, __('is not an endpoint of a known push service'))
  end

  def keys_are_valid
    validate_key(:p256dh, P256DH_BYTES)
    validate_key(:auth, AUTH_BYTES)
  end

  def validate_key(attribute, bytes)
    value = self[attribute]
    return if value.blank?
    return if Base64.urlsafe_decode64(value).bytesize == bytes

    errors.add(attribute, __('is not a valid key'))
  rescue ArgumentError
    errors.add(attribute, __('is not a valid key'))
  end
end
