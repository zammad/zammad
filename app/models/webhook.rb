# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Webhook < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasCollectionUpdate
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  before_save    :reset_custom_payload
  before_destroy Webhook::EnsureNoRelatedObjects

  validates :name, presence: true
  validate :validate_endpoint
  validate :validate_custom_payload

  validates :note, length: { maximum: 500 }
  sanitized_html :note

  store :preferences

  private

  def reset_custom_payload
    return true if customized_payload

    self.custom_payload = nil

    true
  end

  def validate_endpoint
    uri = URI.parse(endpoint)

    errors.add(:endpoint, __('The provided endpoint is invalid, no http or https protocol was specified.')) if !uri.is_a?(URI::HTTP)
    errors.add(:endpoint, __('The provided endpoint is invalid, no hostname was specified.')) if uri.host.blank?
  rescue URI::InvalidURIError
    errors.add :endpoint, __('The provided endpoint is invalid.')
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
end
