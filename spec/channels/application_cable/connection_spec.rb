# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  context 'when user session is present' do
    let(:session_id)         { '123_456' }
    let(:extra_session_data) { {} }

    before do
      private_session_id = Rack::Session::SessionId.new(session_id).private_id

      session = create(:active_session, session_id: private_session_id, user: user)
      session.update!(data: session.data.merge(extra_session_data)) if extra_session_data.present?

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

      it 'connects but sets no user if the user in session is inactive' do
        user.update!(active: false)

        connect

        expect(connection).to have_attributes(current_user: be_nil, sid: session_id)
      end

      context 'when maintenance mode is enabled' do
        before { Setting.set('maintenance_mode', true) }

        it 'connects but sets no user' do
          connect

          expect(connection).to have_attributes(current_user: be_nil, sid: session_id)
        end

        context 'when the user has maintenance permissions' do
          let(:user) { create(:admin) }

          it 'sets current user on connecting' do
            connect

            expect(connection).to have_attributes(current_user: user, sid: session_id)
          end
        end

        context 'when an admin switched to the user' do
          let(:extra_session_data) { { 'switched_from_user_id' => create(:admin).id } }

          it 'sets current user on connecting' do
            connect

            expect(connection).to have_attributes(current_user: user, sid: session_id)
          end
        end
      end

      # Such a session belongs to the admin and is served as the user, so the admin's own state
      #   has to be re-checked here as well (see Auth::SwitchedSession).
      context 'when an admin switched to the user' do
        let(:admin)              { create(:admin) }
        let(:extra_session_data) { { 'switched_from_user_id' => admin.id } }

        it 'sets current user on connecting' do
          connect

          expect(connection).to have_attributes(current_user: user, sid: session_id)
        end

        # Bypasses the callback that drops the admin's sessions (see User::TerminatesSessions),
        #   so that this covers the prerequisite itself.
        context 'when the admin is deactivated' do
          before { admin.update_columns(active: false) }

          it 'connects but sets no user' do
            connect

            expect(connection).to have_attributes(current_user: be_nil, sid: session_id)
          end
        end
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
