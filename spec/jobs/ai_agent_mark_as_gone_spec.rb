# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AIAgentMarkAsGone, type: :job do
  describe '#perform' do
    it 'updates ai_agent_running flag' do
      ticket = create(:ticket, ai_agent_running: true)
      allow(AI::Agent).to receive(:working_on_ticket?).with(ticket).and_return(false)

      described_class.perform_now(ticket)

      ticket.reload
      expect(ticket.ai_agent_running).to be false
    end
  end
end
