# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ResetNotificationsPreferencesJob do
  let(:agent) { create(:agent) }

  before { agent }

  describe '#perform' do
    it 'resets notifications preferences on agents' do
      allow(User).to receive(:reset_notifications_preferences!)

      described_class.perform_now

      expect(User).to have_received(:reset_notifications_preferences!).with(agent)
    end

    it 'broadcasts message when operation is done' do
      allow(Sessions).to receive(:send_to)

      described_class.perform_now(send_to_when_done: 123)

      expect(Sessions)
        .to have_received(:send_to)
        .with(123, { event: 'ticket_agent_default_notifications_applied' })
    end
  end

  describe '#users_scope' do
    let(:customer)       { create(:customer) }
    let(:agent_customer) { create(:agent_and_customer) }

    before { customer && agent_customer }

    it 'returns agents and agent-customers only' do
      expect(described_class.new.send(:users_scope)).to eq([agent, agent_customer])
    end
  end
end
