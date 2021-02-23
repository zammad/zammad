# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Webhook < ApplicationModel
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include HasCollectionUpdate

  before_create :validate_endpoint
  before_update :validate_endpoint

  validates :name, presence: true

  private

  def validate_endpoint
    uri = URI.parse(endpoint)
    raise Exceptions::UnprocessableEntity, 'Invalid endpoint (no http/https)!' if !uri.is_a?(URI::HTTP)
    raise Exceptions::UnprocessableEntity, 'Invalid endpoint (no hostname)!' if uri.host.nil?
  rescue URI::InvalidURIError
    raise Exceptions::UnprocessableEntity, 'Invalid endpoint!'
  end

end
