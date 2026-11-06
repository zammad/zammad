# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::MCPConfirmation < ApplicationModel
  validates :request_id, :action_digest, :expires_at, presence: true

  scope :expired, -> { where(expires_at: ..Time.current) }

  # Only expired ones: an approval refuses a second use until it expires, used or not.
  def self.cleanup
    expired.delete_all

    true
  end
end
