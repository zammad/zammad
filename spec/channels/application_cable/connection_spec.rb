# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  context 'when user session is present' do
    let(:session_id) { '123_456' }

    before do
      private_session_id = Rack::Session::SessionId.new(session_id).private_id

      create(:active_session, session_id: private_session_id, user: user)

      cookies[Zammad::Application::Initializer::SessionStore::SESSION_KEY] = session_id
    end

    context 'when session contains a user' do
      let(:user)       { create(:agent) }

      it 'sets current user on connecting' do
        connect

        expect(connection).to have_attributes(current_user: user, sid: session_id)
      end

      it 'connects but sets no user or sid if user in session no longer exists' do
        user.destroy!

        connect

        expect(connection).to have_attributes(current_user: be_nil, sid: session_id)
      end
    end

    context 'when session contains no user' do
      let(:user) { nil }

      it 'connects but sets no user or sid if user in session no longer exists' do
        connect

        expect(connection).to have_attributes(current_user: be_nil, sid: session_id)
      end
    end
  end

  context 'when no user session present' do
    it 'connects but sets no user or sid' do
      connect

      expect(connection).to have_attributes(current_user: be_nil, sid: be_nil)
    end
  end
end
