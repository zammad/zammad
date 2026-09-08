# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::TerminatesSessions do
  subject(:user) { create(:agent) }

  # Installed ahead of the let! declarations below: let! is itself a before hook, and hooks run
  #   in declaration order. Creating the session rows creates the user, so declaring them first
  #   would let a create-time callback broadcast before this spy exists, leaving the
  #   previously_new_record? guard unchecked by the 'when it is created' examples.
  before do
    allow(ActionCable.server).to receive(:broadcast)
  end

  let(:other_user) { create(:agent) }

  let!(:session)       { create(:active_session, user: user) }
  let!(:other_session) { create(:active_session, user: other_user) }

  # Deliberately no stub of ActionCable.server.remote_connections: the real RemoteConnection is
  #   what enforces that a value is given for every connection identifier, so going through it
  #   pins ApplicationCable::Connection to current_user being its only one.
  let(:disconnect_broadcasting) { "action_cable/#{user.to_gid_param}" }
  let(:disconnect_message)      { { type: 'disconnect', reconnect: true } }

  shared_examples 'revoking what the account holds' do
    it 'destroys the stored sessions of the user' do
      revoke_access

      expect(Session).not_to exist(session.id)
    end

    it 'keeps the stored sessions of other users' do
      revoke_access

      expect(Session).to exist(other_session.id)
    end

    it 'terminates the established connections of the user' do
      revoke_access

      expect(ActionCable.server).to have_received(:broadcast).with(disconnect_broadcasting, disconnect_message)
    end
  end

  shared_examples 'leaving the account alone' do
    it 'keeps the stored sessions of the user' do
      leave_access

      expect(Session).to exist(session.id)
    end

    it 'keeps the established connections of the user' do
      leave_access

      expect(ActionCable.server).not_to have_received(:broadcast).with(disconnect_broadcasting, disconnect_message)
    end
  end

  context 'when the account is deactivated' do
    def revoke_access
      user.update!(active: false)
    end

    include_examples 'revoking what the account holds'
  end

  context 'when the account is deleted' do
    it 'terminates the established connections of the user' do
      user.destroy!

      expect(ActionCable.server).to have_received(:broadcast).with(disconnect_broadcasting, disconnect_message)
    end

    # A deleted account cannot be re-activated, so its rows authorize nobody and are left to
    #   SessionTimeoutJob, which reaps the sessions of deleted users along with everybody else's.
    it 'leaves the stored sessions to be reaped' do
      user.destroy!

      expect(Session).to exist(session.id)
    end
  end

  # SessionsController#switch_to_user puts the switched-to user in the session's 'user_id', so
  #   such a row matches this user while belonging to the admin who switched in.
  context 'with a session an admin switched into the account from' do
    let!(:session) do
      create(:active_session, user: user).tap do |record|
        record.update!(data: record.data.merge('switched_from_user_id' => create(:admin).id))
      end
    end

    it 'keeps the session of the switched-in admin' do
      user.update!(active: false)

      expect(Session).to exist(session.id)
    end
  end

  # The other half of the same row: it belongs to this account, is served as the account it
  #   switched into, and nothing re-checks that this one is still allowed to hold it.
  context 'with a session the account switched into another user from' do
    subject(:user) { create(:admin) }

    let(:switched_to_user) { create(:agent) }

    let!(:switched_session) do
      create(:active_session, user: switched_to_user).tap do |record|
        record.update!(data: record.data.merge('switched_from_user_id' => user.id))
      end
    end

    # Deactivating the last account with admin permissions is refused.
    before { create(:admin) }

    shared_examples 'revoking what the switched session holds' do
      it 'destroys the switched session' do
        revoke_access

        expect(Session).not_to exist(switched_session.id)
      end

      it 'keeps the stored sessions of other users' do
        revoke_access

        expect(Session).to exist(other_session.id)
      end

      # The connections of such a session are identified by the switched-to user, so the
      #   disconnect for this account does not reach them.
      it 'terminates the established connections of the switched-to user' do
        revoke_access

        expect(ActionCable.server)
          .to have_received(:broadcast).with("action_cable/#{switched_to_user.to_gid_param}", disconnect_message)
      end
    end

    context 'when the account is deactivated' do
      def revoke_access
        user.update!(active: false)
      end

      include_examples 'revoking what the switched session holds'

      it 'destroys the own sessions of the user as well' do
        revoke_access

        expect(Session).not_to exist(session.id)
      end
    end

    context 'when the account is deleted' do
      def revoke_access
        user.destroy!
      end

      include_examples 'revoking what the switched session holds'

      it 'leaves the own sessions of the user to be reaped' do
        revoke_access

        expect(Session).to exist(session.id)
      end
    end
  end

  context 'with an unrelated change' do
    def leave_access
      user.update!(lastname: 'Changed')
    end

    include_examples 'leaving the account alone'
  end

  context 'with an inactive user' do
    subject(:user) { create(:agent, active: false) }

    # Only the connection guard is load-bearing here: the session row is inserted after the user
    #   exists, so no ordering makes it observe a create-time destroy.
    context 'when it is created' do
      def leave_access
        user
      end

      include_examples 'leaving the account alone'
    end

    context 'when it is activated' do
      def leave_access
        user.update!(active: true)
      end

      include_examples 'leaving the account alone'
    end
  end
end
