# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Webhook < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasCollectionUpdate

  before_destroy Webhook::EnsureNoRelatedObjects

  validates :name, presence: true
  validate :validate_endpoint

  validates :note, length: { maximum: 500 }
  sanitized_html :note

  private

  def validate_endpoint
    uri = URI.parse(endpoint)

    errors.add(:endpoint, __('The provided endpoint is invalid, no http or https protocol was specified.')) if !uri.is_a?(URI::HTTP)
    errors.add(:endpoint, __('The provided endpoint is invalid, no hostname was specified.')) if uri.host.blank?
  rescue URI::InvalidURIError
    errors.add :endpoint, __('The provided endpoint is invalid.')
  end
end
