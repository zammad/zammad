require 'rails_helper'
require 'models/concerns/has_groups_examples'
require 'models/concerns/has_roles_examples'
require 'models/concerns/has_groups_permissions_examples'
require 'models/concerns/can_lookup_examples'

RSpec.describe User do
  include_examples 'HasGroups', group_access_factory: :agent_user
  include_examples 'HasRoles', group_access_factory: :agent_user
  include_examples 'HasGroups and Permissions', group_access_no_permission_factory: :user
  include_examples 'CanLookup'

  subject(:user) { create(:user) }

  describe 'attributes' do
    describe '#login_failed' do
      before { user.update(login_failed: 1) }

      it 'resets failed login count when password is changed' do
        expect { user.update(password: Faker::Internet.password) }
          .to change { user.login_failed }.to(0)
      end
    end

    describe '#password' do
      context 'when set to plaintext password' do
        it 'hashes password before saving to DB' do
          user.password = 'password'

          expect { user.save }
            .to change { user.password }.to(PasswordHash.crypt('password'))
        end
      end

      context 'when set to SHA2 digest (to facilitate OTRS imports)' do
        it 'does not re-hash before saving' do
          user.password = "{sha2}#{Digest::SHA2.hexdigest('password')}"

          expect { user.save }.not_to change { user.password }
        end
      end

      context 'when set to Argon2 digest' do
        it 'does not re-hash before saving' do
          user.password = PasswordHash.crypt('password')

          expect { user.save }.not_to change { user.password }
        end
      end
    end

    describe '#phone' do
      subject(:user) { create(:user, phone: orig_number) }

      context 'when included on create' do
        let(:orig_number) { '1234567890' }

        it 'adds corresponding CallerId record' do
          expect { user }
            .to change { Cti::CallerId.where(caller_id: orig_number).count }.by(1)
        end
      end

      context 'when added on update' do
        let(:orig_number) { nil }
        let(:new_number) { '1234567890' }

        before { user } # create user

        it 'adds corresponding CallerId record' do
          expect { user.update(phone: new_number) }
            .to change { Cti::CallerId.where(caller_id: new_number).count }.by(1)
        end
      end

      context 'when falsely added on update (change: [nil, ""])' do
        let(:orig_number) { nil }
        let(:new_number)  { '' }

        before { user } # create user

        it 'does not attempt to update CallerId record' do
          allow(Cti::CallerId).to receive(:build).with(any_args)

          expect(Cti::CallerId.where(object: 'User', o_id: user.id).count)
            .to eq(0)

          expect { user.update(phone: new_number) }
            .to change { Cti::CallerId.where(object: 'User', o_id: user.id).count }.by(0)

          expect(Cti::CallerId).not_to have_received(:build)
        end
      end

      context 'when removed on update' do
        let(:orig_number) { '1234567890' }
        let(:new_number) { nil }

        before { user } # create user

        it 'removes corresponding CallerId record' do
          expect { user.update(phone: nil) }
            .to change { Cti::CallerId.where(caller_id: orig_number).count }.by(-1)
        end
      end

      context 'when changed on update' do
        let(:orig_number) { '1234567890' }
        let(:new_number)  { orig_number.next }

        before { user } # create user

        it 'replaces CallerId record' do
          # rubocop:disable Layout/MultilineMethodCallIndentation
          expect { user.update(phone: new_number) }
            .to change { Cti::CallerId.where(caller_id: orig_number).count }.by(-1)
            .and change { Cti::CallerId.where(caller_id: new_number).count }.by(1)
          # rubocop:enable Layout/MultilineMethodCallIndentation
        end
      end
    end
  end

  describe '#max_login_failed?' do
    it { is_expected.to respond_to(:max_login_failed?) }

    context 'with password_max_login_failed setting' do
      before { Setting.set('password_max_login_failed', 5) }
      before { user.update(login_failed: 5) }

      it 'returns true once user’s #login_failed count exceeds the setting' do
        expect { user.update(login_failed: 6) }
          .to change { user.max_login_failed? }.to(true)
      end
    end

    context 'without password_max_login_failed setting' do
      before { Setting.set('password_max_login_failed', nil) }
      before { user.update(login_failed: 0) }

      it 'defaults to 0' do
        expect { user.update(login_failed: 1) }
          .to change { user.max_login_failed? }.to(true)
      end
    end
  end

  describe '#out_of_office_agent' do
    it { is_expected.to respond_to(:out_of_office_agent) }

    context 'when user has no designated substitute' do
      it 'returns nil' do
        expect(user.out_of_office_agent).to be(nil)
      end
    end

    context 'when user has designated substitute, and is out of office' do
      let(:substitute) { create(:user) }
      subject(:user) do
        create(:user,
               out_of_office:                true,
               out_of_office_start_at:       Time.zone.yesterday,
               out_of_office_end_at:         Time.zone.tomorrow,
               out_of_office_replacement_id: substitute.id,)
      end

      it 'returns the designated substitute' do
        expect(user.out_of_office_agent).to eq(substitute)
      end
    end
  end

  describe '.authenticate' do
    subject(:user) { create(:user, password: password) }
    let(:password) { Faker::Internet.password }

    context 'with valid credentials' do
      it 'returns the matching user' do
        expect(described_class.authenticate(user.login, password))
          .to eq(user)
      end
    end

    context 'with valid credentials, but exceeding failed login limit' do
      before { user.update(login_failed: 999) }

      it 'returns nil' do
        expect(described_class.authenticate(user.login, password))
          .to be(nil)
      end
    end

    context 'with valid user and invalid password' do
      it 'increments failed login count' do
        expect { described_class.authenticate(user.login, password.next) }
          .to change { user.reload.login_failed }.by(1)
      end

      it 'returns nil' do
        expect(described_class.authenticate(user.login, password.next)).to be(nil)
      end
    end

    context 'with inactive user’s login' do
      before { user.update(active: false) }

      it 'returns nil' do
        expect(described_class.authenticate(user.login, password)).to be(nil)
      end
    end

    context 'with non-existent user login' do
      it 'returns nil' do
        expect(described_class.authenticate('john.doe', password)).to be(nil)
      end
    end

    context 'with empty login string' do
      it 'returns nil' do
        expect(described_class.authenticate('', password)).to be(nil)
      end
    end

    context 'with empty password string' do
      it 'returns nil' do
        expect(described_class.authenticate(user.login, '')).to be(nil)
      end
    end
  end

  describe '#by_reset_token' do
    let(:token) { create(:token_password_reset) }
    subject(:user) { token.user }

    context 'with a valid token' do
      it 'returns the matching user' do
        expect(described_class.by_reset_token(token.name)).to eq(user)
      end
    end

    context 'with an invalid token' do
      it 'returns nil' do
        expect(described_class.by_reset_token('not-existing')).to be(nil)
      end
    end
  end

  describe '#password_reset_via_token' do
    let!(:token) { create(:token_password_reset) }
    subject(:user) { token.user }

    it 'changes the password of the token user and destroys the token' do
      expect { described_class.password_reset_via_token(token.name, Faker::Internet.password) }
        .to change { user.reload.password }
        .and change { Token.count }.by(-1)
    end
  end

  describe '.identify' do
    it 'returns users by given login' do
      expect(User.identify(user.login)).to eq(user)
    end

    it 'returns users by given email' do
      expect(User.identify(user.email)).to eq(user)
    end
  end

  describe '#access?' do

    let(:role_with_admin_user_permissions) do
      create(:role).tap do |role|
        role.permission_grant('admin.user')
      end
    end
    let(:admin_with_admin_user_permissions) { create(:user, roles: [role_with_admin_user_permissions]) }

    let(:role_without_admin_user_permissions) do
      create(:role).tap do |role|
        role.permission_grant('admin.tag')
      end
    end
    let(:admin_without_admin_user_permissions) { create(:user, roles: [role_without_admin_user_permissions]) }

    context 'read' do

      context 'admin' do

        let(:requested) { create(:admin_user) }

        it 'is possible for admin.user' do
          requester = admin_with_admin_user_permissions
          access    = requested.access?(requester, 'read')
          expect(access).to be(true)
        end

        it 'is possible for sub admin without admin.user' do
          requester = admin_without_admin_user_permissions
          access    = requested.access?(requester, 'read')
          expect(access).to be(true)
        end

        it 'is possible for agent' do
          requester = create(:agent_user)
          access    = requested.access?(requester, 'read')
          expect(access).to be(true)
        end

        it 'is not possible for customer' do
          requester = create(:customer_user)
          access    = requested.access?(requester, 'read')
          expect(access).to be(false)
        end
      end

      context 'agent' do

        let(:requested) { create(:agent_user) }

        it 'is possible for admin.user' do
          requester = admin_with_admin_user_permissions
          access    = requested.access?(requester, 'read')
          expect(access).to be(true)
        end

        it 'is possible for sub admin without admin.user' do
          requester = admin_without_admin_user_permissions
          access    = requested.access?(requester, 'read')
          expect(access).to be(true)
        end

        it 'is possible for agent' do
          requester = create(:agent_user)
          access    = requested.access?(requester, 'read')
          expect(access).to be(true)
        end

        it 'is not possible for customer' do
          requester = create(:customer_user)
          access    = requested.access?(requester, 'read')
          expect(access).to be(false)
        end
      end

      context 'customer' do

        let(:requested) { create(:customer_user) }

        it 'is possible for admin.user' do
          requester = admin_with_admin_user_permissions
          access    = requested.access?(requester, 'read')
          expect(access).to be(true)
        end

        it 'is possible for sub admin without admin.user' do
          requester = admin_without_admin_user_permissions
          access    = requested.access?(requester, 'read')
          expect(access).to be(true)
        end

        it 'is possible for agent' do
          requester = create(:agent_user)
          access    = requested.access?(requester, 'read')
          expect(access).to be(true)

        end

        it 'is possible for same customer' do
          access = requested.access?(requested, 'read')
          expect(access).to be(true)
        end

        it 'is possible for same organization' do
          organization = create(:organization)
          requester    = create(:customer_user, organization: organization)
          requested.update!(organization: organization)
          access = requested.access?(requester, 'read')
          expect(access).to be(true)
        end

        it 'is not possible for different customer' do
          requester = create(:customer_user)
          access    = requested.access?(requester, 'read')
          expect(access).to be(false)
        end
      end
    end

    context 'change' do

      context 'admin' do

        let(:requested) { create(:admin_user) }

        it 'is possible for admin.user' do
          requester = admin_with_admin_user_permissions
          access    = requested.access?(requester, 'change')
          expect(access).to be(true)
        end

        it 'is not possible for sub admin without admin.user' do
          requester = admin_without_admin_user_permissions
          access    = requested.access?(requester, 'change')
          expect(access).to be(false)
        end

        it 'is not possible for same for sub admin without admin.user' do
          access = admin_without_admin_user_permissions.access?(admin_without_admin_user_permissions, 'change')
          expect(access).to be(false)
        end

        it 'is not possible for agent' do
          requester = create(:agent_user)
          access    = requested.access?(requester, 'change')
          expect(access).to be(false)
        end

        it 'is not possible for customer' do
          requester = create(:customer_user)
          access    = requested.access?(requester, 'change')
          expect(access).to be(false)
        end
      end

      context 'agent' do

        let(:requested) { create(:agent_user) }

        it 'is possible for admin.user' do
          requester = admin_with_admin_user_permissions
          access    = requested.access?(requester, 'change')
          expect(access).to be(true)
        end

        it 'is not possible for sub admin without admin.user' do
          requester = admin_without_admin_user_permissions
          access    = requested.access?(requester, 'change')
          expect(access).to be(false)
        end

        it 'is not possible for same agent' do
          access = requested.access?(requested, 'change')
          expect(access).to be(false)
        end

        it 'is not possible for other agent' do
          requester = create(:agent_user)
          access    = requested.access?(requester, 'change')
          expect(access).to be(false)
        end

        it 'is not possible for customer' do
          requester = create(:customer_user)
          access    = requested.access?(requester, 'change')
          expect(access).to be(false)
        end
      end

      context 'customer' do

        let(:requested) { create(:customer_user) }

        it 'is possible for admin.user' do
          requester = admin_with_admin_user_permissions
          access    = requested.access?(requester, 'change')
          expect(access).to be(true)
        end

        it 'is not possible for sub admin without admin.user' do
          requester = admin_without_admin_user_permissions
          access    = requested.access?(requester, 'change')
          expect(access).to be(false)
        end

        it 'is possible for agent' do
          requester = create(:agent_user)
          access    = requested.access?(requester, 'change')
          expect(access).to be(true)

        end

        it 'is not possible for same customer' do
          access = requested.access?(requested, 'change')
          expect(access).to be(false)
        end

        it 'is not possible for same organization' do
          organization = create(:organization)
          requester    = create(:customer_user, organization: organization)
          requested.update!(organization: organization)
          access = requested.access?(requester, 'change')
          expect(access).to be(false)
        end

        it 'is not possible for different customer' do
          requester = create(:customer_user)
          access    = requested.access?(requester, 'change')
          expect(access).to be(false)
        end
      end
    end

    context 'delete' do

      context 'admin' do

        let(:requested) { create(:admin_user) }

        it 'is possible for admin.user' do
          requester = admin_with_admin_user_permissions
          access    = requested.access?(requester, 'delete')
          expect(access).to be(true)
        end

        it 'is not possible for sub admin without admin.user' do
          requester = admin_without_admin_user_permissions
          access    = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end

        it 'is not possible for agent' do
          requester = create(:agent_user)
          access    = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end

        it 'is not possible for customer' do
          requester = create(:customer_user)
          access    = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end
      end

      context 'agent' do

        let(:requested) { create(:agent_user) }

        it 'is possible for admin.user' do
          requester = admin_with_admin_user_permissions
          access    = requested.access?(requester, 'delete')
          expect(access).to be(true)
        end

        it 'is not possible for sub admin without admin.user' do
          requester = admin_without_admin_user_permissions
          access    = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end

        it 'is not possible for agent' do
          requester = create(:agent_user)
          access    = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end

        it 'is not possible for customer' do
          requester = create(:customer_user)
          access    = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end
      end

      context 'customer' do

        let(:requested) { create(:customer_user) }

        it 'is possible for admin.user' do
          requester = admin_with_admin_user_permissions
          access    = requested.access?(requester, 'delete')
          expect(access).to be(true)
        end

        it 'is not possible for sub admin without admin.user' do
          requester = admin_without_admin_user_permissions
          access    = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end

        it 'is not possible for agent' do
          requester = create(:agent_user)
          access    = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end

        it 'is not possible for same customer' do
          access = requested.access?(requested, 'delete')
          expect(access).to be(false)
        end

        it 'is not possible for same organization' do
          organization = create(:organization)
          requester    = create(:customer_user, organization: organization)
          requested.update!(organization: organization)
          access = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end

        it 'is not possible for different customer' do
          requester = create(:customer_user)
          access    = requested.access?(requester, 'delete')
          expect(access).to be(false)
        end
      end
    end
  end

  describe 'system-wide agent limit' do

    def current_agent_count
      User.with_permissions('ticket.agent').count
    end

    let(:agent_role) { Role.lookup(name: 'Agent') }
    let(:admin_role) { Role.lookup(name: 'Admin') }

    describe '#validate_agent_limit_by_role' do
      context 'for Integer value of system_agent_limit' do
        context 'before exceeding the agent limit' do
          before { Setting.set('system_agent_limit', current_agent_count + 1) }

          it 'grants agent creation' do
            expect { create(:agent_user) }
              .to change { current_agent_count }.by(1)
          end

          it 'grants role change' do
            future_agent = create(:customer_user)

            expect { future_agent.roles = [agent_role] }
              .to change { current_agent_count }.by(1)
          end

          describe 'role updates' do
            let(:agent) { create(:agent_user) }

            it 'grants update by instances' do
              expect { agent.roles = [admin_role, agent_role] }
                .not_to raise_error
            end

            it 'grants update by id (Integer)' do
              expect { agent.role_ids = [admin_role.id, agent_role.id] }
                .not_to raise_error
            end

            it 'grants update by id (String)' do
              expect { agent.role_ids = [admin_role.id.to_s, agent_role.id.to_s] }
                .not_to raise_error
            end
          end
        end

        context 'when exceeding the agent limit' do
          it 'creation of new agents' do
            Setting.set('system_agent_limit', current_agent_count + 2)

            create_list(:agent_user, 2)

            expect { create(:agent_user) }
              .to raise_error(Exceptions::UnprocessableEntity)
              .and change { current_agent_count }.by(0)
          end

          it 'prevents role change' do
            Setting.set('system_agent_limit', current_agent_count)

            future_agent = create(:customer_user)

            expect { future_agent.roles = [agent_role] }
              .to raise_error(Exceptions::UnprocessableEntity)
              .and change { current_agent_count }.by(0)
          end
        end
      end

      context 'for String value of system_agent_limit' do
        context 'before exceeding the agent limit' do
          before { Setting.set('system_agent_limit', (current_agent_count + 1).to_s) }

          it 'grants agent creation' do
            expect { create(:agent_user) }
              .to change { current_agent_count }.by(1)
          end

          it 'grants role change' do
            future_agent = create(:customer_user)

            expect { future_agent.roles = [agent_role] }
              .to change { current_agent_count }.by(1)
          end

          describe 'role updates' do
            let(:agent) { create(:agent_user) }

            it 'grants update by instances' do
              expect { agent.roles = [admin_role, agent_role] }
                .not_to raise_error
            end

            it 'grants update by id (Integer)' do
              expect { agent.role_ids = [admin_role.id, agent_role.id] }
                .not_to raise_error
            end

            it 'grants update by id (String)' do
              expect { agent.role_ids = [admin_role.id.to_s, agent_role.id.to_s] }
                .not_to raise_error
            end
          end
        end

        context 'when exceeding the agent limit' do
          it 'creation of new agents' do
            Setting.set('system_agent_limit', (current_agent_count + 2).to_s)

            create_list(:agent_user, 2)

            expect { create(:agent_user) }
              .to raise_error(Exceptions::UnprocessableEntity)
              .and change { current_agent_count }.by(0)
          end

          it 'prevents role change' do
            Setting.set('system_agent_limit', current_agent_count.to_s)

            future_agent = create(:customer_user)

            expect { future_agent.roles = [agent_role] }
              .to raise_error(Exceptions::UnprocessableEntity)
              .and change { current_agent_count }.by(0)
          end
        end
      end
    end

    describe '#validate_agent_limit_by_attributes' do
      context 'for Integer value of system_agent_limit' do
        before { Setting.set('system_agent_limit', current_agent_count) }

        context 'when exceeding the agent limit' do
          it 'prevents re-activation of agents' do
            inactive_agent = create(:agent_user, active: false)

            expect { inactive_agent.update!(active: true) }
              .to raise_error(Exceptions::UnprocessableEntity)
              .and change { current_agent_count }.by(0)
          end
        end
      end

      context 'for String value of system_agent_limit' do
        before { Setting.set('system_agent_limit', current_agent_count.to_s) }

        context 'when exceeding the agent limit' do
          it 'prevents re-activation of agents' do
            inactive_agent = create(:agent_user, active: false)

            expect { inactive_agent.update!(active: true) }
              .to raise_error(Exceptions::UnprocessableEntity)
              .and change { current_agent_count }.by(0)
          end
        end
      end
    end
  end
end
