# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Webhook < ApplicationModel
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include HasCollectionUpdate

  before_destroy Webhook::EnsureNoRelatedObjects

  validates :name, presence: true
  validate :validate_endpoint

  private

  def validate_endpoint
    uri = URI.parse(endpoint)

    errors.add(:endpoint, 'Invalid endpoint (no http/https)!') if !uri.is_a?(URI::HTTP)
    errors.add(:endpoint, 'Invalid endpoint (no hostname)!') if uri.host.nil?
  rescue URI::InvalidURIError
    errors.add :endpoint, 'Invalid endpoint!'
  end
end
