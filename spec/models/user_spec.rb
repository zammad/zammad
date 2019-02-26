require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/has_groups_examples'
require 'models/concerns/has_roles_examples'
require 'models/concerns/has_groups_permissions_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/can_lookup_examples'

RSpec.describe User, type: :model do
  it_behaves_like 'ApplicationModel', can_assets: { associations: :organization }
  it_behaves_like 'HasGroups', group_access_factory: :agent_user
  it_behaves_like 'HasRoles', group_access_factory: :agent_user
  it_behaves_like 'HasXssSanitizedNote', model_factory: :user
  it_behaves_like 'HasGroups and Permissions', group_access_no_permission_factory: :user
  it_behaves_like 'CanBeImported'
  it_behaves_like 'CanLookup'

  subject(:user) { create(:user) }
  let(:admin)    { create(:admin_user) }
  let(:agent)    { create(:agent_user) }
  let(:customer) { create(:customer_user) }

  describe 'Class methods:' do
    describe '.authenticate' do
      subject(:user) { create(:user, password: password) }
      let(:password) { Faker::Internet.password }

      context 'with valid credentials' do
        it 'returns the matching user' do
          expect(described_class.authenticate(user.login, password))
            .to eq(user)
        end

        context 'but exceeding failed login limit' do
          before { user.update(login_failed: 999) }

          it 'returns nil' do
            expect(described_class.authenticate(user.login, password))
              .to be(nil)
          end
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

    describe '.identify' do
      it 'returns users by given login' do
        expect(User.identify(user.login)).to eq(user)
      end

      it 'returns users by given email' do
        expect(User.identify(user.email)).to eq(user)
      end
    end
  end

  describe 'Instance methods:' do
    describe '#max_login_failed?' do
      it { is_expected.to respond_to(:max_login_failed?) }

      context 'with "password_max_login_failed" setting' do
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

    describe '#access?' do
      context 'when an admin' do
        subject(:user) { create(:user, roles: [partial_admin_role]) }

        context 'with "admin.user" privileges' do
          let(:partial_admin_role) do
            create(:role).tap { |role| role.permission_grant('admin.user') }
          end

          context 'wants to read, change, or delete any user' do
            it 'returns true' do
              expect(admin.access?(user, 'read')).to be(true)
              expect(admin.access?(user, 'change')).to be(true)
              expect(admin.access?(user, 'delete')).to be(true)
              expect(agent.access?(user, 'read')).to be(true)
              expect(agent.access?(user, 'change')).to be(true)
              expect(agent.access?(user, 'delete')).to be(true)
              expect(customer.access?(user, 'read')).to be(true)
              expect(customer.access?(user, 'change')).to be(true)
              expect(customer.access?(user, 'delete')).to be(true)
              expect(user.access?(user, 'read')).to be(true)
              expect(user.access?(user, 'change')).to be(true)
              expect(user.access?(user, 'delete')).to be(true)
            end
          end
        end

        context 'without "admin.user" privileges' do
          let(:partial_admin_role) do
            create(:role).tap { |role| role.permission_grant('admin.tag') }
          end

          context 'wants to read any user' do
            it 'returns true' do
              expect(admin.access?(user, 'read')).to be(true)
              expect(agent.access?(user, 'read')).to be(true)
              expect(customer.access?(user, 'read')).to be(true)
              expect(user.access?(user, 'read')).to be(true)
            end
          end

          context 'wants to change or delete any user' do
            it 'returns false' do
              expect(admin.access?(user, 'change')).to be(false)
              expect(admin.access?(user, 'delete')).to be(false)
              expect(agent.access?(user, 'change')).to be(false)
              expect(agent.access?(user, 'delete')).to be(false)
              expect(customer.access?(user, 'change')).to be(false)
              expect(customer.access?(user, 'delete')).to be(false)
              expect(user.access?(user, 'change')).to be(false)
              expect(user.access?(user, 'delete')).to be(false)
            end
          end
        end
      end

      context 'when an agent' do
        subject(:user) { create(:agent_user) }

        context 'wants to read any user' do
          it 'returns true' do
            expect(admin.access?(user, 'read')).to be(true)
            expect(agent.access?(user, 'read')).to be(true)
            expect(customer.access?(user, 'read')).to be(true)
            expect(user.access?(user, 'read')).to be(true)
          end
        end

        context 'wants to change' do
          context 'any admin or agent' do
            it 'returns false' do
              expect(admin.access?(user, 'change')).to be(false)
              expect(agent.access?(user, 'change')).to be(false)
              expect(user.access?(user, 'change')).to be(false)
            end
          end

          context 'any customer' do
            it 'returns true' do
              expect(customer.access?(user, 'change')).to be(true)
            end
          end
        end

        context 'wants to delete any user' do
          it 'returns false' do
            expect(admin.access?(user, 'delete')).to be(false)
            expect(agent.access?(user, 'delete')).to be(false)
            expect(customer.access?(user, 'delete')).to be(false)
            expect(user.access?(user, 'delete')).to be(false)
          end
        end
      end

      context 'when a customer' do
        subject(:user) { create(:customer_user, :with_org) }
        let(:colleague) { create(:customer_user, organization: user.organization) }

        context 'wants to read' do
          context 'any admin, agent, or customer from a different organization' do
            it 'returns false' do
              expect(admin.access?(user, 'read')).to be(false)
              expect(agent.access?(user, 'read')).to be(false)
              expect(customer.access?(user, 'read')).to be(false)
            end
          end

          context 'any customer from the same organization' do
            it 'returns true' do
              expect(user.access?(user, 'read')).to be(true)
              expect(colleague.access?(user, 'read')).to be(true)
            end
          end
        end

        context 'wants to change or delete any user' do
          it 'returns false' do
            expect(admin.access?(user, 'change')).to be(false)
            expect(admin.access?(user, 'delete')).to be(false)
            expect(agent.access?(user, 'change')).to be(false)
            expect(agent.access?(user, 'delete')).to be(false)
            expect(customer.access?(user, 'change')).to be(false)
            expect(customer.access?(user, 'delete')).to be(false)
            expect(colleague.access?(user, 'change')).to be(false)
            expect(colleague.access?(user, 'delete')).to be(false)
            expect(user.access?(user, 'change')).to be(false)
            expect(user.access?(user, 'delete')).to be(false)
          end
        end
      end
    end
  end

  describe 'Attributes:' do
    describe '#login_failed' do
      before { user.update(login_failed: 1) }

      it 'is reset to 0 when password is updated' do
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
          expect { user.update(phone: new_number) }
            .to change { Cti::CallerId.where(caller_id: orig_number).count }.by(-1)
            .and change { Cti::CallerId.where(caller_id: new_number).count }.by(1)
        end
      end
    end
  end

  describe 'Associations:' do
    describe '#organization' do
      describe 'email domain-based assignment' do
        subject(:user) { build(:user) }

        context 'when not set on creation' do
          before { user.assign_attributes(organization: nil) }

          context 'and #email domain matches an existing Organization#domain' do
            before { user.assign_attributes(email: 'user@example.com') }
            let(:organization) { create(:organization, domain: 'example.com') }

            context 'and Organization#domain_assignment is false (default)' do
              before { organization.update(domain_assignment: false) }

              it 'remains nil' do
                expect { user.save }.not_to change { user.organization }
              end
            end

            context 'and Organization#domain_assignment is true' do
              before { organization.update(domain_assignment: true) }

              it 'is automatically set to matching Organization' do
                expect { user.save }
                  .to change { user.organization }.to(organization)
              end
            end
          end

          context 'and #email domain doesn’t match any Organization#domain' do
            before { user.assign_attributes(email: 'user@example.net') }
            let(:organization) { create(:organization, domain: 'example.com') }

            context 'and Organization#domain_assignment is true' do
              before { organization.update(domain_assignment: true) }

              it 'remains nil' do
                expect { user.save }.not_to change { user.organization }
              end
            end
          end
        end

        context 'when set on creation' do
          before { user.assign_attributes(organization: specified_organization) }
          let(:specified_organization) { create(:organization, domain: 'example.net') }

          context 'and #email domain matches a DIFFERENT Organization#domain' do
            before { user.assign_attributes(email: 'user@example.com') }
            let!(:matching_organization) { create(:organization, domain: 'example.com') }

            context 'and Organization#domain_assignment is true' do
              before { matching_organization.update(domain_assignment: true) }

              it 'is NOT automatically set to matching Organization' do
                expect { user.save }
                  .not_to change { user.organization }.from(specified_organization)
              end
            end
          end
        end
      end
    end
  end

  describe 'Callbacks, Observers, & Async Transactions -' do
    describe 'System-wide agent limit checks:' do
      let(:agent_role) { Role.lookup(name: 'Agent') }
      let(:admin_role) { Role.lookup(name: 'Admin') }
      let(:current_agents) { User.with_permissions('ticket.agent') }

      describe '#validate_agent_limit_by_role' do
        context 'for Integer value of system_agent_limit' do
          context 'before exceeding the agent limit' do
            before { Setting.set('system_agent_limit', current_agents.count + 1) }

            it 'grants agent creation' do
              expect { create(:agent_user) }
                .to change { current_agents.count }.by(1)
            end

            it 'grants role change' do
              future_agent = create(:customer_user)

              expect { future_agent.roles = [agent_role] }
                .to change { current_agents.count }.by(1)
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
              Setting.set('system_agent_limit', current_agents.count + 2)

              create_list(:agent_user, 2)

              expect { create(:agent_user) }
                .to raise_error(Exceptions::UnprocessableEntity)
                .and change { current_agents.count }.by(0)
            end

            it 'prevents role change' do
              Setting.set('system_agent_limit', current_agents.count)

              future_agent = create(:customer_user)

              expect { future_agent.roles = [agent_role] }
                .to raise_error(Exceptions::UnprocessableEntity)
                .and change { current_agents.count }.by(0)
            end
          end
        end

        context 'for String value of system_agent_limit' do
          context 'before exceeding the agent limit' do
            before { Setting.set('system_agent_limit', (current_agents.count + 1).to_s) }

            it 'grants agent creation' do
              expect { create(:agent_user) }
                .to change { current_agents.count }.by(1)
            end

            it 'grants role change' do
              future_agent = create(:customer_user)

              expect { future_agent.roles = [agent_role] }
                .to change { current_agents.count }.by(1)
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
              Setting.set('system_agent_limit', (current_agents.count + 2).to_s)

              create_list(:agent_user, 2)

              expect { create(:agent_user) }
                .to raise_error(Exceptions::UnprocessableEntity)
                .and change { current_agents.count }.by(0)
            end

            it 'prevents role change' do
              Setting.set('system_agent_limit', current_agents.count.to_s)

              future_agent = create(:customer_user)

              expect { future_agent.roles = [agent_role] }
                .to raise_error(Exceptions::UnprocessableEntity)
                .and change { current_agents.count }.by(0)
            end
          end
        end
      end

      describe '#validate_agent_limit_by_attributes' do
        context 'for Integer value of system_agent_limit' do
          before { Setting.set('system_agent_limit', current_agents.count) }

          context 'when exceeding the agent limit' do
            it 'prevents re-activation of agents' do
              inactive_agent = create(:agent_user, active: false)

              expect { inactive_agent.update!(active: true) }
                .to raise_error(Exceptions::UnprocessableEntity)
                .and change { current_agents.count }.by(0)
            end
          end
        end

        context 'for String value of system_agent_limit' do
          before { Setting.set('system_agent_limit', current_agents.count.to_s) }

          context 'when exceeding the agent limit' do
            it 'prevents re-activation of agents' do
              inactive_agent = create(:agent_user, active: false)

              expect { inactive_agent.update!(active: true) }
                .to raise_error(Exceptions::UnprocessableEntity)
                .and change { current_agents.count }.by(0)
            end
          end
        end
      end
    end

    describe 'Cti::CallerId syncing:' do
      context 'with a #phone attribute' do
        subject(:user) { build(:user, phone: '1234567890') }

        it 'adds CallerId record on creation (via Cti::CallerId.build)' do
          expect(Cti::CallerId).to receive(:build).with(user)

          user.save
        end

        it 'updates CallerId record on touch/update (via Cti::CallerId.build)' do
          user.save

          expect(Cti::CallerId).to receive(:build).with(user)

          user.touch
        end

        it 'destroys CallerId record on deletion' do
          user.save

          expect { user.destroy }
            .to change { Cti::CallerId.count }.by(-1)
        end
      end
    end

    describe 'Cti::Log syncing:' do
      context 'with existing Log records' do
        context 'for incoming calls from an unknown number' do
          let!(:log) { create(:'cti/log', :with_preferences, from: '1234567890', direction: 'in') }

          context 'when creating a new user with that number' do
            subject(:user) { build(:user, phone: log.from) }

            it 'populates #preferences[:from] hash in all associated Log records (in a bg job)' do
              expect do
                user.save
                Observer::Transaction.commit
                Scheduler.worker(true)
              end.to change { log.reload.preferences[:from]&.first }
                .to(hash_including('caller_id' => user.phone))
            end
          end

          context 'when updating a user with that number' do
            subject(:user) { create(:user) }

            it 'populates #preferences[:from] hash in all associated Log records (in a bg job)' do
              expect do
                user.update(phone: log.from)
                Observer::Transaction.commit
                Scheduler.worker(true)
              end.to change { log.reload.preferences[:from]&.first }
                .to(hash_including('object' => 'User', 'o_id' => user.id))
            end
          end

          context 'when creating a new user with an empty number' do
            subject(:user) { build(:user, phone: '') }

            it 'does not modify any Log records' do
              expect do
                user.save
                Observer::Transaction.commit
                Scheduler.worker(true)
              end.not_to change { log.reload.attributes }
            end
          end

          context 'when creating a new user with no number' do
            subject(:user) { build(:user, phone: nil) }

            it 'does not modify any Log records' do
              expect do
                user.save
                Observer::Transaction.commit
                Scheduler.worker(true)
              end.not_to change { log.reload.attributes }
            end
          end
        end

        context 'for incoming calls from the given user' do
          subject(:user) { create(:user, phone: '1234567890') }
          let!(:logs) { create_list(:'cti/log', 5, :with_preferences, from: user.phone, direction: 'in') }

          context 'when updating #phone attribute' do
            context 'to another number' do
              it 'empties #preferences[:from] hash in all associated Log records (in a bg job)' do
                expect do
                  user.update(phone: '0123456789')
                  Observer::Transaction.commit
                  Scheduler.worker(true)
                end.to change { logs.map(&:reload).map(&:preferences) }
                  .to(Array.new(5) { {} })
              end
            end

            context 'to an empty string' do
              it 'empties #preferences[:from] hash in all associated Log records (in a bg job)' do
                expect do
                  user.update(phone: '')
                  Observer::Transaction.commit
                  Scheduler.worker(true)
                end.to change { logs.map(&:reload).map(&:preferences) }
                  .to(Array.new(5) { {} })
              end
            end

            context 'to nil' do
              it 'empties #preferences[:from] hash in all associated Log records (in a bg job)' do
                expect do
                  user.update(phone: nil)
                  Observer::Transaction.commit
                  Scheduler.worker(true)
                end.to change { logs.map(&:reload).map(&:preferences) }
                  .to(Array.new(5) { {} })
              end
            end
          end

          context 'when updating attributes other than #phone' do
            it 'does not modify any Log records' do
              expect do
                user.update(mobile: '2345678901')
                Observer::Transaction.commit
                Scheduler.worker(true)
              end.not_to change { logs.map(&:reload).map(&:attributes) }
            end
          end
        end
      end
    end
  end

end
