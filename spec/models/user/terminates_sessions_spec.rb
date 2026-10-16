# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::TerminatesSessions do
  subject(:user) { create(:agent) }

  # Installed ahead of the let! declarations below, which create the user: a broadcast on creation
  #   would otherwise go unseen, leaving unchecked that only updates are remembered (after_update).
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

    # Rails runs the commit callbacks only on the last instance of a record saved in a transaction.
    context 'when another instance of the record is saved afterwards in the same transaction' do
      def revoke_access
        User.transaction do
          user.update!(active: false)
          User.find(user.id).touch
        end
      end

      include_examples 'revoking what the account holds'

      it 'keeps the stored sessions created afterwards on activation' do
        revoke_access
        new_session = create(:active_session, user: user)
        user.update!(active: true)

        expect(Session).to exist(new_session.id)
      end
    end

    # A rolled back savepoint discards only what was noted inside it.
    context 'when a membership change in a nested transaction is rolled back afterwards' do
      def revoke_access
        User.transaction do
          user.update!(active: false)

          User.transaction(requires_new: true) do
            user.update!(organization: create(:organization))

            raise ActiveRecord::Rollback
          end
        end
      end

      include_examples 'revoking what the account holds'
    end

    context 'when a save in a nested transaction is rolled back afterwards' do
      def revoke_access
        User.transaction do
          user.update!(active: false)

          User.transaction(requires_new: true) do
            user.update!(lastname: 'Changed')

            raise ActiveRecord::Rollback
          end
        end
      end

      include_examples 'revoking what the account holds'
    end
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

  shared_examples 'renewing the connections of the account' do
    it 'keeps the stored sessions of the user' do
      change_membership

      expect(Session).to exist(session.id)
    end

    it 'terminates the established connections of the user' do
      change_membership

      expect(ActionCable.server).to have_received(:broadcast).with(disconnect_broadcasting, disconnect_message)
    end
  end

  # A connection is served as the user it was authenticated as, memberships included, so it has
  #   to be made anew once they change.
  context 'when the primary organization is set' do
    def change_membership
      user.update!(organization: create(:organization))
    end

    include_examples 'renewing the connections of the account'
  end

  context 'with a primary organization' do
    subject(:user) { create(:agent, organization: organization) }

    let(:organization) { create(:organization) }

    context 'when it changes' do
      def change_membership
        user.update!(organization: create(:organization))
      end

      include_examples 'renewing the connections of the account'

      # A new ticket touches its customer (see Ticket::TouchesAssociations), which replaces the
      #   saved changes ahead of the commit.
      context 'when the record is touched afterwards in the same transaction' do
        def change_membership
          User.transaction do
            user.update!(organization: create(:organization))
            user.touch
          end
        end

        include_examples 'renewing the connections of the account'
      end

      context 'when another instance of the record is saved afterwards in the same transaction' do
        def change_membership
          User.transaction do
            user.update!(organization: create(:organization))
            User.find(user.id).touch
          end
        end

        include_examples 'renewing the connections of the account'
      end

      context 'when a membership change in a nested transaction is rolled back afterwards' do
        def change_membership
          User.transaction do
            user.update!(organization: create(:organization))

            User.transaction(requires_new: true) do
              user.organizations << create(:organization)

              raise ActiveRecord::Rollback
            end
          end
        end

        include_examples 'renewing the connections of the account'
      end

      context 'when it changes in a nested transaction that is rolled back' do
        def leave_access
          User.transaction do
            user.update!(lastname: 'Changed')

            User.transaction(requires_new: true) do
              user.update!(organization: create(:organization))

              raise ActiveRecord::Rollback
            end
          end
        end

        include_examples 'leaving the account alone'
      end
    end

    context 'when it is removed' do
      def change_membership
        user.update!(organization: nil)
      end

      include_examples 'renewing the connections of the account'
    end

    context 'when a secondary organization is added' do
      def change_membership
        user.update!(organization_ids: [create(:organization).id])
      end

      include_examples 'renewing the connections of the account'
    end

    # Written through the association alone, the record is never saved along with the change.
    context 'when a secondary organization is added through the association alone' do
      def change_membership
        user.organizations << create(:organization)
      end

      include_examples 'renewing the connections of the account'
    end

    # Dropped from the organization side, the user is only touched (see Organization#member_update).
    context 'when the organization drops the user as a member' do
      def change_membership
        organization.update!(member_ids: organization.member_ids - [user.id])
      end

      include_examples 'renewing the connections of the account'
    end

    # A new organization fires its member callbacks on assignment, before it and its join rows
    #   exist; a connection renewed at that point would be denied the membership.
    context 'when a new organization is created with the user as a secondary member' do
      it 'terminates the established connections of the user only once it is a member', :aggregate_failures do
        organization_ids_at_disconnect = nil
        allow(ActionCable.server).to receive(:broadcast).with(disconnect_broadcasting, disconnect_message) do
          organization_ids_at_disconnect = User.find(user.id).organization_ids
        end

        new_organization = create(:organization, secondary_members: [user])

        expect(ActionCable.server).to have_received(:broadcast).with(disconnect_broadcasting, disconnect_message).once
        expect(organization_ids_at_disconnect).to eq([new_organization.id])
      end
    end

    context 'when a new organization is created with the user as a member' do
      it 'terminates the established connections of the user only once it is a member', :aggregate_failures do
        organization_id_at_disconnect = nil
        allow(ActionCable.server).to receive(:broadcast).with(disconnect_broadcasting, disconnect_message) do
          organization_id_at_disconnect = User.find(user.id).organization_id
        end

        new_organization = create(:organization, members: [user])

        expect(ActionCable.server).to have_received(:broadcast).with(disconnect_broadcasting, disconnect_message).once
        expect(organization_id_at_disconnect).to eq(new_organization.id)
      end
    end

    context 'with a secondary organization' do
      subject(:user) { create(:agent, organization: organization, organizations: [secondary_organization]) }

      let(:secondary_organization) { create(:organization) }

      context 'when it is removed' do
        def change_membership
          user.update!(organization_ids: [])
        end

        include_examples 'renewing the connections of the account'
      end

      context 'when it drops the user as a secondary member' do
        def change_membership
          secondary_organization.update!(secondary_member_ids: [])
        end

        include_examples 'renewing the connections of the account'
      end

      # The join rows go with the organization, without the association callbacks.
      context 'when it is destroyed' do
        def change_membership
          secondary_organization.destroy
        end

        include_examples 'renewing the connections of the account'
      end

      context 'when its removal was rolled back' do
        def leave_access
          User.transaction do
            user.update!(organization_ids: [])

            raise ActiveRecord::Rollback
          end

          user.update!(lastname: 'Changed')
        end

        include_examples 'leaving the account alone'
      end

      context 'when it is removed through the association alone' do
        def change_membership
          user.organizations.delete(secondary_organization)
        end

        include_examples 'renewing the connections of the account'
      end

      context 'when its removal through the association alone was rolled back' do
        def leave_access
          User.transaction do
            user.organization_ids = []

            raise ActiveRecord::Rollback
          end

          user.update!(lastname: 'Changed')
        end

        include_examples 'leaving the account alone'
      end

      # Also guards that the organizations a record is built with do not count on its first
      #   update.
      context 'when it is assigned again' do
        def leave_access
          user.update!(organization_ids: [secondary_organization.id])
        end

        include_examples 'leaving the account alone'
      end
    end
  end

  context 'when a role is added' do
    def change_membership
      user.update!(role_ids: user.role_ids + [create(:role).id])
    end

    include_examples 'renewing the connections of the account'
  end

  # Agent permissions fill in the notification preferences, which saves the record in the middle
  #   of the role assignment.
  context 'when a customer is given a role with agent permissions' do
    subject(:user) { create(:customer) }

    def change_membership
      user.update!(role_ids: user.role_ids + [create(:role, :agent).id])
    end

    include_examples 'renewing the connections of the account'
  end

  context 'with a role' do
    subject(:user) { create(:agent, roles: Role.where(name: 'Agent') + [role]) }

    let(:role) { create(:role) }

    context 'when it is removed' do
      def change_membership
        user.update!(role_ids: user.role_ids - [role.id])
      end

      include_examples 'renewing the connections of the account'
    end

    # From the role side, the user is written through the association of the role alone.
    context 'when it drops the user as a member' do
      def change_membership
        role.users.delete(user)
      end

      include_examples 'renewing the connections of the account'
    end

    # The join rows go with the role, without the association callbacks.
    context 'when it is destroyed' do
      def change_membership
        role.destroy!
      end

      include_examples 'renewing the connections of the account'
    end
  end

  context 'when a role takes the user as a member' do
    def change_membership
      create(:role).users << user
    end

    include_examples 'renewing the connections of the account'
  end

  context 'when a new role is created with the user as a member' do
    it 'terminates the established connections of the user only once it is a member', :aggregate_failures do
      role_ids_at_disconnect = nil
      allow(ActionCable.server).to receive(:broadcast).with(disconnect_broadcasting, disconnect_message) do
        role_ids_at_disconnect = User.find(user.id).role_ids
      end

      role = create(:role, users: [user])

      expect(ActionCable.server).to have_received(:broadcast).with(disconnect_broadcasting, disconnect_message).once
      expect(role_ids_at_disconnect).to include(role.id)
    end
  end

  # The nested save (see above) persists the deactivation ahead of the save that was asked for,
  #   which is then left without changes of its own.
  context 'when a customer is deactivated and given a role with agent permissions at once' do
    subject(:user) { create(:customer) }

    def revoke_access
      user.update!(active: false, role_ids: user.role_ids + [create(:role, :agent).id])
    end

    include_examples 'revoking what the account holds'

    it 'does not terminate the established connections of the user again on activation' do
      revoke_access
      user.update!(active: true)

      expect(ActionCable.server).to have_received(:broadcast).with(disconnect_broadcasting, disconnect_message).once
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
