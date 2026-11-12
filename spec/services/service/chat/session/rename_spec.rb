# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Chat::Session::Rename do
  subject(:service) { described_class.with_current_user(agent).execute(session:, name:) }

  let(:topic)         { create(:chat, name: 'Support') }
  let(:agent)         { create(:agent) }
  let(:session_owner) { agent }
  let(:session_state) { 'running' }
  let(:name)          { 'Pricing question' }
  let(:session)       { create(:'chat/session', chat: topic, state: session_state, user: session_owner, name: 'Old name') }

  it 'requires a current user' do
    expect { described_class.execute(session:, name:) }.to raise_error(%r{Current user is required})
  end

  it 'names the session and returns it', :aggregate_failures do
    expect(service).to eq(session)
    expect(session.reload.name).to eq('Pricing question')
  end

  context 'with a blank name' do
    let(:name) { '   ' }

    it 'takes the name away' do
      service

      expect(session.reload.name).to be_nil
    end
  end

  %w[waiting closed].each do |state|
    context "with a #{state} session of the agent" do
      let(:session_state) { state }

      it 'names it as well' do
        expect(service.reload.name).to eq('Pricing question')
      end
    end
  end

  context 'with a session of another agent' do
    let(:session_owner) { create(:agent) }

    it 'is forbidden and leaves the name alone', :aggregate_failures do
      expect { service }.to raise_error(Exceptions::Forbidden)

      expect(session.reload.name).to eq('Old name')
    end
  end

  context 'with a session nobody runs' do
    let(:session_owner) { nil }
    let(:session_state) { 'waiting' }

    it 'is forbidden' do
      expect { service }.to raise_error(Exceptions::Forbidden)
    end
  end
end
