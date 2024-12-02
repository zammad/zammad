# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class PublicLink < ApplicationModel
  include HasDefaultModelUserRelations
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  include CanPriorization
  include ChecksClientNotification
  include PublicLink::TriggersSubscriptions

  AVAILABLE_SCREENS = %w[login signup password_reset].freeze

  validates :link,   presence: true, length: { maximum: 500 }
  validates :title,  presence: true, length: { maximum: 200 }
  validates :screen, presence: true, inclusion: { in: AVAILABLE_SCREENS }

  before_validation :check_link

  default_scope { order(:prio, :id) }

  client_notification_send_type 'public'

  private

  def check_link
    return true if link.blank?

    uri = URI.parse(link)
    raise Exceptions::UnprocessableEntity, "Invalid link '#{link}'." if !uri.is_a?(URI::HTTP)

    true
  end
end
