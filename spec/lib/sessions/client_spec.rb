# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Client do
  let(:client_id)        { SecureRandom.uuid }
  let(:overview_backend) { instance_double(Sessions::Backend::TicketOverviewList, push: nil) }
  let(:activity_backend) { instance_double(Sessions::Backend::ActivityStream, push: nil) }

  let(:session_user_data) { { 'id' => user.id } }

  before do
    # Leave the fetch loop after one run, it would run forever otherwise.
    allow(BackgroundServices).to receive(:shutdown_requested).and_return(false, true)

    allow(Sessions::Backend::TicketOverviewList).to receive(:new).and_return(overview_backend)
    allow(Sessions::Backend::ActivityStream).to receive(:new).and_return(activity_backend)

    Sessions.create(client_id, session_user_data, { type: 'websocket' })
  end

  after { Sessions.destroy(client_id) }

  context 'with an active user' do
    let(:user) { create(:agent) }

    it 'pushes data to the client' do
      described_class.new(client_id, 'node_id')

      expect(overview_backend).to have_received(:push)
    end
  end

  context 'with an inactive user' do
    let(:user) { create(:agent) }

    before { user.update!(active: false) }

    it 'pushes no data to the client' do
      described_class.new(client_id, 'node_id')

      expect(overview_backend).not_to have_received(:push)
    end
  end

  context 'with a deleted user' do
    let(:user) { create(:agent) }

    before { user.destroy! }

    it 'pushes no data to the client' do
      described_class.new(client_id, 'node_id')

      expect(overview_backend).not_to have_received(:push)
    end
  end

  context 'with maintenance mode enabled' do
    let(:user) { create(:agent) }

    before { Setting.set('maintenance_mode', true) }

    it 'pushes no data to the client' do
      described_class.new(client_id, 'node_id')

      expect(overview_backend).not_to have_received(:push)
    end

    context 'when the user has maintenance permissions' do
      let(:user) { create(:admin) }

      it 'pushes data to the client' do
        described_class.new(client_id, 'node_id')

        expect(overview_backend).to have_received(:push)
      end
    end

    context 'when an admin switched to the user' do
      let(:session_user_data) { { 'id' => user.id, 'switched_from_user_id' => create(:admin).id } }

      it 'pushes data to the client' do
        described_class.new(client_id, 'node_id')

        expect(overview_backend).to have_received(:push)
      end
    end
  end

  # Such a session belongs to the admin and is served as the user, so the admin's own state has
  #   to be re-checked here as well (see Auth::SwitchedSession).
  context 'with an admin switched to the user' do
    let(:user)              { create(:agent) }
    let(:admin)             { create(:admin) }
    let(:session_user_data) { { 'id' => user.id, 'switched_from_user_id' => admin.id } }

    it 'pushes data to the client' do
      described_class.new(client_id, 'node_id')

      expect(overview_backend).to have_received(:push)
    end

    # Bypasses the callback that drops the admin's sessions (see User::TerminatesSessions), so
    #   that this covers the prerequisite itself - the legacy transport serves a copy of the
    #   session anyway, which no destroyed record reaches.
    context 'when the admin is deactivated' do
      before { admin.update_columns(active: false) }

      it 'pushes no data to the client' do
        described_class.new(client_id, 'node_id')

        expect(overview_backend).not_to have_received(:push)
      end
    end
  end
end
