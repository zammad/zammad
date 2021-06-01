# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::ChatAgentState do

  let(:client_id) { rand(123_456_789) }
  let(:chat) { Chat.first }

  let(:user) do
    create(:agent, preferences: {
             chat: {
               active: {
                 chat.id.to_s => 'on'
               }
             }
           })
  end

  let!(:instance) do
    Sessions.create(client_id, { 'id' => user.id }, {})
    Sessions.queue(client_id)
    described_class.new(
      payload:   {
        'data' => {
          'active' => active
        },
      },
      user_id:   user.id,
      client_id: client_id,
      clients:   {},
      session:   {
        'id' => user.id
      },
    )
  end

  let(:record) { create(:'chat/agent', updated_by: user) }

  before do
    Setting.set('chat', true)
  end

  context 'when state changes' do

    let(:active) { !record.active }

    it 'broadcasts agent state update' do
      allow(Chat).to receive(:broadcast_agent_state_update)
      instance.run
      expect(Chat).to have_received(:broadcast_agent_state_update)
    end
  end

  context "when state doesn't change" do

    let(:active) { record.active }

    it "doesn't broadcasts agent state update" do
      allow(Chat).to receive(:broadcast_agent_state_update)
      instance.run
      expect(Chat).not_to have_received(:broadcast_agent_state_update)
    end
  end
end
