# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe BackgroundServices::Service::ProcessSessionsJobs do
  subject(:service) { described_class.new(manager: BackgroundServices.new([])) }

  describe 'starting client session threads' do
    let(:client_id) { SecureRandom.uuid }

    let(:session_user_data) { { 'id' => user.id } }

    before do
      allow(service).to receive(:fetch_client_ids).and_return([client_id])
      allow(service).to receive(:start_client_session_thread)

      Sessions.create(client_id, session_user_data, { type: 'websocket' })
    end

    after { Sessions.destroy(client_id) }

    context 'with an active user' do
      let(:user) { create(:agent) }

      it 'starts a thread for the session' do
        service.send(:start_threads_for_new_client_sessions)

        expect(service).to have_received(:start_client_session_thread).with(client_id)
      end
    end

    # Sessions::Client#fetch ends the thread of a session whose user is no longer active, so it
    #   must not be started again here, it would only be restarted over and over.
    context 'with an inactive user' do
      let(:user) { create(:agent, active: false) }

      it 'starts no thread for the session' do
        service.send(:start_threads_for_new_client_sessions)

        expect(service).not_to have_received(:start_client_session_thread)
      end
    end

    context 'with a deleted user' do
      let(:user) { create(:agent).tap(&:destroy!) }

      it 'starts no thread for the session' do
        service.send(:start_threads_for_new_client_sessions)

        expect(service).not_to have_received(:start_client_session_thread)
      end
    end

    context 'with maintenance mode enabled' do
      let(:user) { create(:agent) }

      before { Setting.set('maintenance_mode', true) }

      it 'starts no thread for the session' do
        service.send(:start_threads_for_new_client_sessions)

        expect(service).not_to have_received(:start_client_session_thread)
      end

      context 'when the user has maintenance permissions' do
        let(:user) { create(:admin) }

        it 'starts a thread for the session' do
          service.send(:start_threads_for_new_client_sessions)

          expect(service).to have_received(:start_client_session_thread).with(client_id)
        end
      end

      context 'when an admin switched to the user' do
        let(:session_user_data) { { 'id' => user.id, 'switched_from_user_id' => create(:admin).id } }

        it 'starts a thread for the session' do
          service.send(:start_threads_for_new_client_sessions)

          expect(service).to have_received(:start_client_session_thread).with(client_id)
        end
      end
    end

    # Such a session belongs to the admin and is served as the user, so the admin's own state
    #   has to be re-checked here as well (see Auth::SwitchedSession).
    context 'with an admin switched to the user' do
      let(:user)              { create(:agent) }
      let(:admin)             { create(:admin) }
      let(:session_user_data) { { 'id' => user.id, 'switched_from_user_id' => admin.id } }

      it 'starts a thread for the session' do
        service.send(:start_threads_for_new_client_sessions)

        expect(service).to have_received(:start_client_session_thread).with(client_id)
      end

      # Sessions::Client#fetch ends the thread of such a session once the admin is deactivated,
      #   so it must not be started again here, it would only be restarted over and over.
      context 'when the admin is deactivated' do
        before { admin.update_columns(active: false) }

        it 'starts no thread for the session' do
          service.send(:start_threads_for_new_client_sessions)

          expect(service).not_to have_received(:start_client_session_thread)
        end
      end
    end
  end
end
