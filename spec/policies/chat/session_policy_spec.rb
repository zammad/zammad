# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Chat::SessionPolicy do
  subject(:policy) { described_class.new(user, session) }

  let(:topic)         { create(:chat, name: 'Support') }
  let(:user)          { create(:agent) }
  let(:session_state) { 'running' }
  let(:session_owner) { user }
  let(:session)       { create(:'chat/session', chat: topic, state: session_state, user: session_owner) }
  let(:chat_enabled)  { true }

  before do
    Setting.set('chat', chat_enabled)
  end

  context 'with the agent of the session' do
    it { is_expected.to permit_actions(%i[read_conversation subscribe agent_update_access]) }

    context 'when chat is disabled' do
      let(:chat_enabled) { false }

      it { is_expected.to forbid_action(:agent_update_access) }
    end

    context 'with a closed session' do
      let(:session_state) { 'closed' }

      it { is_expected.to permit_actions(%i[read_conversation subscribe agent_update_access]) }
    end

    # A transfer puts the session back into a queue without taking it from its agent.
    context 'with a session sent back to a queue' do
      let(:session_state) { 'waiting' }

      it { is_expected.to permit_actions(%i[read_conversation agent_update_access]) }
      it { is_expected.to forbid_action(:subscribe) }
    end

    context 'when wrapped in a user context' do
      subject(:policy) { described_class.new(UserContext.new(user), session) }

      it { is_expected.to permit_actions(%i[read_conversation subscribe agent_update_access]) }
    end
  end

  # As in the old UI, a session found through search opens for any chat agent.
  context 'with another agent' do
    let(:session_owner) { create(:agent) }

    it { is_expected.to permit_actions(%i[read_conversation subscribe]) }
    it { is_expected.to forbid_action(:agent_update_access) }

    context 'with a closed session' do
      let(:session_state) { 'closed' }

      it { is_expected.to permit_actions(%i[read_conversation subscribe]) }
    end
  end

  context 'with a session nobody runs' do
    let(:session_owner) { nil }
    let(:session_state) { 'waiting' }

    it { is_expected.to permit_action(:read_conversation) }
    it { is_expected.to forbid_actions(%i[subscribe agent_update_access]) }
  end

  context 'with a user who may not chat' do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }

    it { is_expected.to forbid_actions(%i[read_conversation subscribe agent_update_access]) }
  end
end
