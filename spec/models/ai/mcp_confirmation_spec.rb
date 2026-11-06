# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::MCPConfirmation, type: :model do
  describe '.cleanup' do
    def confirmation(expires_at:, consumed_at: nil)
      described_class.create!(request_id: SecureRandom.uuid, action_digest: 'digest', expires_at:, consumed_at:)
    end

    it 'deletes the expired confirmations only, also the used ones, and keeps those still to be answered or refused' do
      confirmation(expires_at: 1.minute.ago)
      confirmation(expires_at: 1.minute.ago, consumed_at: 5.minutes.ago)
      pending = confirmation(expires_at: 5.minutes.from_now)
      used    = confirmation(expires_at: 5.minutes.from_now, consumed_at: 1.minute.ago)

      described_class.cleanup

      expect(described_class.all).to contain_exactly(pending, used)
    end
  end
end
