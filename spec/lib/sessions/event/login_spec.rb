# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::Login do
  subject(:run_event) do
    described_class.new(
      payload:   payload,
      headers:   headers,
      client_id: client_id,
      client:    client,
    ).run
  end

  let(:client)             { {} }
  let(:client_id)          { 'sess_id' }
  let(:payload)            { { 'event' => 'login' } }
  let(:session_id)         { SecureRandom.hex(16) }
  let(:extra_session_data) { {} }
  let(:user)               { create(:agent) }

  let(:origin)         { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}" }
  let(:session_cookie) { "#{Zammad::Application::Initializer::SessionStore::SESSION_KEY}=#{session_id}" }
  let(:headers)        { { 'Origin' => origin, 'Cookie' => "other=1; #{session_cookie}" } }

  before do
    allow(Sessions).to receive(:create)
    allow(Sessions).to receive(:send)

    session = create(:active_session, session_id: Rack::Session::SessionId.new(session_id).private_id, user: user)
    session.update!(data: session.data.merge(extra_session_data)) if extra_session_data.present?
  end

  shared_examples 'starting a session for the user' do
    it 'starts a session for the user' do
      run_event

      expect(Sessions).to have_received(:create).with(client_id, { 'id' => user.id }, { type: 'websocket' })
    end

    it 'stores the user in the client session' do
      run_event

      expect(client[:session]).to eq({ 'id' => user.id })
    end
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
    include_examples 'starting a session for the user'

    context 'with lower-case header names' do
      let(:headers) { { 'origin' => origin, 'cookie' => session_cookie } }

      include_examples 'starting a session for the user'
    end

    context 'with a differently cased origin' do
      let(:headers) { { 'Origin' => origin.upcase, 'Cookie' => session_cookie } }

      include_examples 'starting a session for the user'
    end

    context 'with an alternative FQDN configured' do
      let(:alternative_fqdn) { 'support.example.org' }

      before do
        allow(Setting).to receive(:get).and_call_original
        allow(Setting).to receive(:get).with('alternative_fqdn').and_return(alternative_fqdn)
      end

      include_examples 'starting a session for the user'

      context 'with the alternative origin' do
        let(:origin) { "#{Setting.get('http_type')}://#{alternative_fqdn}" }

        include_examples 'starting a session for the user'
      end

      context 'with an origin only sharing the prefix of the alternative origin' do
        let(:origin) { "#{Setting.get('http_type')}://#{alternative_fqdn}.evil.example.org" }

        include_examples 'starting a session without a user'
      end
    end

    context 'with a localhost origin' do
      let(:headers) { { 'Origin' => 'https://localhost:3001', 'Cookie' => session_cookie } }

      include_examples 'starting a session for the user'
    end

    context 'with an origin of a sibling host on the same site' do
      let(:headers) { { 'Origin' => "#{Setting.get('http_type')}://evil.#{Setting.get('fqdn')}", 'Cookie' => session_cookie } }

      include_examples 'starting a session without a user'
    end

    context 'with an origin of a foreign host' do
      let(:headers) { { 'Origin' => 'https://evil.example.org', 'Cookie' => session_cookie } }

      include_examples 'starting a session without a user'
    end

    context 'with an origin using a different scheme' do
      let(:headers) { { 'Origin' => "#{Setting.get('http_type') == 'https' ? 'http' : 'https'}://#{Setting.get('fqdn')}", 'Cookie' => session_cookie } }

      include_examples 'starting a session without a user'
    end

    context 'with an origin only sharing the prefix of the configured origin' do
      let(:headers) { { 'Origin' => "#{origin}.evil.example.org", 'Cookie' => session_cookie } }

      include_examples 'starting a session without a user'
    end

    context 'with a localhost origin without port' do
      let(:headers) { { 'Origin' => 'https://localhost.evil.example.org', 'Cookie' => session_cookie } }

      include_examples 'starting a session without a user'
    end

    context 'without an origin header' do
      let(:headers) { { 'Cookie' => session_cookie } }

      include_examples 'starting a session without a user'
    end

    context 'with a session cookie of an unknown session' do
      let(:headers) { { 'Origin' => origin, 'Cookie' => "#{Zammad::Application::Initializer::SessionStore::SESSION_KEY}=#{SecureRandom.hex(16)}" } }

      include_examples 'starting a session without a user'
    end

    context 'without a session cookie' do
      let(:headers) { { 'Origin' => origin, 'Cookie' => 'other=1' } }

      include_examples 'starting a session without a user'
    end

    context 'without any headers' do
      let(:headers) { nil }

      include_examples 'starting a session without a user'
    end

    context 'with a session id supplied in the payload only' do
      let(:headers) { { 'Origin' => origin } }
      let(:payload) { { 'event' => 'login', 'session_id' => session_id } }

      include_examples 'starting a session without a user'
    end

    context 'with a session id in the payload differing from the cookie' do
      let(:other_user)       { create(:agent) }
      let(:other_session_id) { SecureRandom.hex(16) }
      let(:payload)          { { 'event' => 'login', 'session_id' => other_session_id } }

      before do
        create(:active_session, session_id: Rack::Session::SessionId.new(other_session_id).private_id, user: other_user)
      end

      include_examples 'starting a session for the user'
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
    before { Setting.set('maintenance_mode', true) }

    include_examples 'starting a session without a user'

    context 'when the user has maintenance permissions' do
      let(:user) { create(:admin) }

      include_examples 'starting a session for the user'
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
    let(:admin)              { create(:admin) }
    let(:extra_session_data) { { 'switched_from_user_id' => admin.id } }

    # Bypasses the callback that drops the admin's sessions (see User::TerminatesSessions), so
    #   that this covers the prerequisite itself.
    before { admin.update_columns(active: false) }

    include_examples 'starting a session without a user'
  end
end
