# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::Login do
  subject(:run_event) do
    described_class.new(
      payload:   { 'event' => 'login', 'session_id' => session_id },
      client_id: client_id,
      client:    client,
    ).run
  end

  let(:client)             { {} }
  let(:client_id)          { 'sess_id' }
  let(:session_id)         { SecureRandom.hex(16) }
  let(:extra_session_data) { {} }

  before do
    allow(Sessions).to receive(:create)
    allow(Sessions).to receive(:send)

    session = create(:active_session, session_id: Rack::Session::SessionId.new(session_id).private_id, user: user)
    session.update!(data: session.data.merge(extra_session_data)) if extra_session_data.present?
  end

  shared_examples 'starting a session without a user' do
    it 'starts a session without a user' do
      run_event

      expect(Sessions).to have_received(:create).with(client_id, {}, { type: 'websocket' })
    end

    it 'stores no user in the client session' do
      run_event

      expect(client[:session]).to eq({})
    end
  end

  context 'with an active user' do
    let(:user) { create(:agent) }

    it 'starts a session for the user' do
      run_event

      expect(Sessions).to have_received(:create).with(client_id, { 'id' => user.id }, { type: 'websocket' })
    end

    it 'stores the user in the client session' do
      run_event

      expect(client[:session]).to eq({ 'id' => user.id })
    end
  end

  context 'with an inactive user' do
    let(:user) { create(:agent, active: false) }

    include_examples 'starting a session without a user'
  end

  context 'without a user in the session' do
    let(:user) { nil }

    include_examples 'starting a session without a user'
  end

  context 'with maintenance mode enabled' do
    let(:user) { create(:agent) }

    before { Setting.set('maintenance_mode', true) }

    include_examples 'starting a session without a user'

    context 'when the user has maintenance permissions' do
      let(:user) { create(:admin) }

      it 'starts a session for the user' do
        run_event

        expect(Sessions).to have_received(:create).with(client_id, { 'id' => user.id }, { type: 'websocket' })
      end
    end

    # The prerequisites are re-checked while the session is served, where the session record is
    #   not available - so the exemption has to travel with the session.
    context 'when an admin switched to the user' do
      let(:switched_from_user_id) { create(:admin).id }
      let(:extra_session_data)    { { 'switched_from_user_id' => switched_from_user_id } }

      it 'starts a session for the user, carrying the switched user along' do
        run_event

        expect(Sessions)
          .to have_received(:create)
          .with(client_id, { 'id' => user.id, 'switched_from_user_id' => switched_from_user_id }, { type: 'websocket' })
      end
    end
  end

  # Such a session belongs to the admin and is served as the user, so the admin's own state has
  #   to be re-checked here as well (see Auth::SwitchedSession).
  context 'with a deactivated admin switched to the user' do
    let(:user)               { create(:agent) }
    let(:admin)              { create(:admin) }
    let(:extra_session_data) { { 'switched_from_user_id' => admin.id } }

    # Bypasses the callback that drops the admin's sessions (see User::TerminatesSessions), so
    #   that this covers the prerequisite itself.
    before { admin.update_columns(active: false) }

    include_examples 'starting a session without a user'
  end
end
