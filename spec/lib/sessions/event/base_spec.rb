# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::Base do

  describe '#initialize' do
    it 'does not accept unknown params' do
      expect { described_class.new(clients: {}, user_id: 1) }.to raise_error(ArgumentError)
    end
  end

  describe 'restoring the session user' do
    # The session of a web socket connection is restored once, at login time, so it has to be
    #   re-checked for every event that is handled for it.
    let(:event_class) do
      Class.new(described_class) do
        database_connection_required

        def run
          @session
        end
      end
    end

    let(:session)   { { 'id' => user.id } }
    let(:event)     { event_class.new(session: session, client_id: 'sess_id', client: {}) }

    context 'with an active user' do
      let(:user) { create(:agent) }

      it 'keeps the user in the session' do
        expect(event.run).to eq({ 'id' => user.id })
      end
    end

    context 'with an inactive user' do
      let(:user) { create(:agent, active: false) }

      it 'removes the user from the session' do
        expect(event.run).to eq({})
      end
    end

    context 'with a deleted user' do
      let(:user) { create(:agent).tap(&:destroy!) }

      it 'removes the user from the session' do
        expect(event.run).to eq({})
      end
    end

    context 'with maintenance mode enabled' do
      let(:user) { create(:agent) }

      before { Setting.set('maintenance_mode', true) }

      it 'removes the user from the session' do
        expect(event.run).to eq({})
      end

      context 'when the user has maintenance permissions' do
        let(:user) { create(:admin) }

        it 'keeps the user in the session' do
          expect(event.run).to eq({ 'id' => user.id })
        end
      end

      context 'when an admin switched to the user' do
        let(:session) { { 'id' => user.id, 'switched_from_user_id' => create(:admin).id } }

        it 'keeps the user in the session' do
          expect(event.run).to eq(session)
        end
      end
    end

    # Such a session belongs to the admin and is served as the user, so the admin's own state
    #   has to be re-checked here as well (see Auth::SwitchedSession).
    context 'with an admin switched to the user' do
      let(:user)    { create(:agent) }
      let(:admin)   { create(:admin) }
      let(:session) { { 'id' => user.id, 'switched_from_user_id' => admin.id } }

      it 'keeps the user in the session' do
        expect(event.run).to eq(session)
      end

      # Bypasses the callback that drops the admin's sessions (see User::TerminatesSessions), so
      #   that this covers the prerequisite itself - the legacy transport serves a copy of the
      #   session anyway, which no destroyed record reaches.
      context 'when the admin is deactivated' do
        before { admin.update_columns(active: false) }

        it 'removes the user from the session' do
          expect(event.run).to eq({ 'switched_from_user_id' => admin.id })
        end
      end
    end
  end

  describe '#remote_ip' do
    let(:instance) { described_class.new(headers:) }

    context 'without X-Forwarded-For' do
      let(:headers) { {} }

      it 'returns no value' do
        expect(instance.remote_ip).to be_nil
      end
    end

    context 'with X-Forwarded-For' do
      before do
        allow(Rails.application.config.action_dispatch).to receive(:trusted_proxies).and_return(trusted_proxies)
      end

      let(:trusted_proxies) { [IPAddr.new('127.0.0.1'), IPAddr.new('::1')] }

      context 'with external IP' do

        let(:headers) { { 'X-Forwarded-For' => '1.2.3.4 , 5.6.7.8, 127.0.0.1 , ::1' } }

        it 'returns the correct value' do
          expect(instance.remote_ip).to eq('5.6.7.8')
        end
      end

      context 'without external IP' do

        let(:headers) { { 'X-Forwarded-For' => ' 127.0.0.1 , ::1' } }

        it 'returns no value' do
          expect(instance.remote_ip).to be_nil
        end
      end

      context 'with proxies in a trusted address range' do
        let(:trusted_proxies) { [IPAddr.new('192.168.66.0/24')] }
        let(:headers)         { { 'X-Forwarded-For' => '1.2.3.4, 192.168.66.1, 192.168.66.2' } }

        it 'returns the address before the range' do
          expect(instance.remote_ip).to eq('1.2.3.4')
        end
      end

      context 'with a value that is not an IP address' do
        let(:headers) { { 'X-Forwarded-For' => 'unknown, 127.0.0.1' } }

        it 'returns the value' do
          expect(instance.remote_ip).to eq('unknown')
        end
      end

    end

  end
end
