# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/has_groups_examples'
require 'models/concerns/has_history_examples'
require 'models/concerns/has_roles_examples'
require 'models/concerns/has_groups_permissions_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_image_sanitized_note_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/can_csv_import_examples'
require 'models/concerns/can_csv_import_user_examples'
require 'models/concerns/has_object_manager_attributes_examples'
require 'models/user/can_lookup_search_index_attributes_examples'
require 'models/user/performs_geo_lookup_examples'
require 'models/concerns/has_taskbars_examples'
require 'models/concerns/has_recent_closes_examples'
require 'models/concerns/has_two_factor_examples'

RSpec.describe User, type: :model do
  subject(:user) { create(:user) }

  let(:customer) { create(:customer) }
  let(:agent)    { create(:agent) }
  let(:admin)    { create(:admin) }

  it_behaves_like 'ApplicationModel',
                  can_assets: { associations: :organization },
                  can_param:  { sample_data_attribute: :email }
  it_behaves_like 'HasGroups', group_access_factory: :agent
  it_behaves_like 'HasHistory'
  it_behaves_like 'HasRoles', group_access_factory: :agent
  it_behaves_like 'HasXssSanitizedNote', model_factory: :user
  it_behaves_like 'HasImageSanitizedNote', model_factory: :user
  it_behaves_like 'HasGroups and Permissions', group_access_no_permission_factory: :user
  it_behaves_like 'CanBeImported'
  # it_behaves_like 'CanCsvImport', unique_attributes: 'email'
  include_examples 'CanCsvImport - User specific tests'
  it_behaves_like 'HasObjectManagerAttributes'
  it_behaves_like 'CanLookupSearchIndexAttributes'
  it_behaves_like 'HasTaskbars'
  it_behaves_like 'HasRecentCloses'
  it_behaves_like 'UserPerformsGeoLookup'
  it_behaves_like 'Association clears cache', association: :roles
  it_behaves_like 'Association clears cache', association: :organizations
  it_behaves_like 'User::HasTwoFactor'

  describe 'adding a group' do
    it 'invalidates the association ID cache for both the user and the group' do
      agent = create(:agent)
      group = create(:group)

      expect { agent.groups << group }
        .to change { agent.attributes_with_association_ids['group_ids'].keys.count }.by(1)
        .and change { group.attributes_with_association_ids['user_ids'].count }.by(1)
    end
  end

  describe 'Class methods:' do
    describe '.identify' do
      it 'returns users by given login' do
        expect(described_class.identify(user.login)).to eq(user)
      end

      it 'returns users by given email' do
        expect(described_class.identify(user.email)).to eq(user)
      end

      it 'returns nil for empty username' do
        expect(described_class.identify('')).to be_nil
      end
    end

    describe '.reset_notifications_preferences!' do
      let(:sample_notifications) { { sample_notifications: true } }

      def change_setting_ticket_agent_default_notifications
        Setting.set('ticket_agent_default_notifications', sample_notifications)
      end

      context 'when user is agent' do
        before do
          # Create the agent, before the default notifications are set, so
          agent

          change_setting_ticket_agent_default_notifications
        end

        it 'changes existing matrix' do
          expect { described_class.reset_notifications_preferences!(agent) }
            .to change { agent.preferences.dig('notification_config', 'matrix') }
            .to sample_notifications
        end

        it 'sets matrix if preferences are empty' do
          agent.update_columns preferences: nil

          expect { described_class.reset_notifications_preferences!(agent) }
            .to change { agent.preferences&.dig('notification_config', 'matrix') }
            .to(sample_notifications)
            .from(nil)
        end

        it 'does not touch selected groups do' do
          agent.preferences['notification_config']['group_ids'] = ['123']
          agent.save!

          expect { described_class.reset_notifications_preferences!(agent) }
            .not_to change { agent.preferences&.dig('notification_config', 'group_ids') }
        end
      end

      context 'when user is not agent' do
        before do
          # Create the customer, before the default notifications are set, so
          customer

          change_setting_ticket_agent_default_notifications
        end

        it 'does not change existing matrix' do
          expect { described_class.reset_notifications_preferences!(customer) }
            .not_to change { customer.preferences.dig('notification_config', 'matrix') }
        end

        it 'sets matrix if preferences are empty' do
          customer.update_columns preferences: nil

          expect { described_class.reset_notifications_preferences!(customer) }
            .not_to change { customer.preferences&.dig('notification_config', 'matrix') }
            .from(nil)
        end
      end
    end

    describe '.by_mobile' do
      let!(:user)        { create(:customer, mobile: saved_mobile) }
      let(:saved_mobile) { '+4912341234' }

      context 'with a number saved with prefixed +' do
        context 'searching for the same mobile number' do
          it 'finds the user (by direct lookup)' do
            expect(described_class.by_mobile(number: saved_mobile)).to eq(user)
          end
        end

        context 'searching for the E.164 number without prefixed +' do
          it 'finds the user (through CTI lookup)' do
            expect(described_class.by_mobile(number: '4912341234')).to eq(user)
          end
        end
      end

      context 'with a number saved without prefixed +' do
        let(:saved_mobile) { '4912341234' }

        context 'searching for the same mobile number' do
          it 'finds the user (by direct lookup)' do
            expect(described_class.by_mobile(number: saved_mobile)).to eq(user)
          end
        end

        context 'searching for the number prefixed with +' do
          it 'finds the user (through CTI lookup)' do
            expect(described_class.by_mobile(number: '+4912341234')).to eq(user)
          end
        end
      end

      context 'with a non-matching number' do
        it 'does not find the user' do
          expect(described_class.by_mobile(number: '99999999999')).to be_nil
        end
      end
    end
  end

  describe 'Instance methods:' do

    describe '#by_reset_token' do
      subject(:user) { token.user }

      let(:token) { create(:token_password_reset) }

      context 'with a valid token' do
        it 'returns the matching user' do
          expect(described_class.by_reset_token(token.token)).to eq(user)
        end
      end

      context 'with an invalid token' do
        it 'returns nil' do
          expect(described_class.by_reset_token('not-existing')).to be_nil
        end
      end
    end

    describe '#password_reset_via_token' do
      subject(:user) { token.user }

      let!(:token) { create(:token_password_reset) }

      it 'changes the password of the token user and destroys the token' do
        expect { described_class.password_reset_via_token(token.token, 'VYxesRc6O2') }
          .to change { user.reload.password }
          .and change(Token, :count).by(-1)
      end
    end

    describe '#admin_password_auth_new_token' do
      context 'with user role agent' do
        subject(:user) { create(:agent) }

        it 'returns no token' do
          expect(described_class.admin_password_auth_new_token(user.login)).to be_nil
        end
      end

      context 'with user role admin' do
        subject(:user) { create(:admin) }

        it 'returns token' do
          expect(described_class.admin_password_auth_new_token(user.login).keys).to include(:user, :token)
        end

        it 'delete existing tokens when creating multiple times' do
          described_class.admin_password_auth_new_token(user.login)
          described_class.admin_password_auth_new_token(user.login)

          expect(Token.where(action: 'AdminAuth', user_id: user.id).count).to eq(1)
        end
      end
    end

    describe '#admin_password_auth_via_token' do
      context 'with invalid token' do
        it 'returns nil' do
          expect(described_class.admin_password_auth_via_token('not-existing')).to be_nil
        end
      end

      context 'with valid token' do
        let(:user) { create(:admin) }

        it 'returns the matching user' do
          result = described_class.admin_password_auth_new_token(user.login)
          token = result[:token].token
          expect(described_class.admin_password_auth_via_token(token)).to match(user)
        end

        it 'destroys token' do
          result = described_class.admin_password_auth_new_token(user.login)
          token = result[:token].token
          expect { described_class.admin_password_auth_via_token(token) }.to change(Token, :count).by(-1)
        end
      end
    end

    describe '#locale' do
      subject(:user) { create(:user, preferences: preferences) }

      context 'with no #preferences[:locale]' do
        let(:preferences) { {} }

        context 'with default locale' do
          before { Setting.set('locale_default', 'foo') }

          it 'returns the system-wide default locale' do
            expect(user.locale).to eq('foo')
          end
        end

        context 'without default locale' do
          before { Setting.set('locale_default', nil) }

          it 'returns en-us' do
            expect(user.locale).to eq('en-us')
          end
        end
      end

      context 'with a #preferences[:locale]' do
        let(:preferences) { { locale: 'bar' } }

        it 'returns the user’s configured locale' do
          expect(user.locale).to eq('bar')
        end
      end
    end

    describe '#check_login' do
      let(:agent) { create(:agent, login: nil) }

      it 'does use given login' do
        new_agent = create(:agent)
        expect(new_agent.login).not_to end_with('1')
      end

      it 'ensures login is downcase and without white spaces' do
        new_agent = create(:agent, login: ' TestUser ')
        expect(new_agent.login).to eq('testuser')
      end

      it 'returns validation error if the login is already taken' do
        new_agent = build(:agent, login: agent.login)

        new_agent.valid?

        expect(new_agent.errors[:login]).to include('has already been taken')
      end

      context 'when email-as-login was used and is changed' do
        it 'updates login' do
          new_agent = create(:agent, login: nil)

          new_agent.update! email: Faker::Internet.unique.email

          expect(new_agent.login).to eq(new_agent.email)
        end
      end

      context 'when email is empty too' do
        it 'generates auto-login' do
          new_agent = create(:agent, login: nil, email: nil)

          expect(new_agent.login).to start_with('auto-')
        end
      end

      context 'when user_email_multiple_use is enabled' do
        before { Setting.set('user_email_multiple_use', true) }

        context 'when login is given' do
          it 'raises error if the login is already taken' do
            new_agent = build(:agent, login: agent.login)

            new_agent.valid?

            expect(new_agent.errors[:login]).to include('has already been taken')
          end
        end

        context 'when login is not given' do
          it 'uses email as fallback' do
            new_agent = create(:agent, login: nil)

            expect(new_agent.login).to eq(new_agent.email)
          end

          it 'does number up agent logins (1)' do
            new_agent = create(:agent, login: nil, email: agent.email)

            expect(new_agent.login).to eq("#{new_agent.email}1")
          end

          it 'does number up agent logins (5)' do
            new_agent = create(:agent, login: nil, email: agent.email)
            4.times do
              new_agent = create(:agent, login: nil, email: agent.email)
            end

            expect(new_agent.login).to eq("#{new_agent.email}5")
          end

          it 'does backup with uuid in cases of many duplicates' do
            new_agent = create(:agent, login: nil, email: agent.email)
            20.times do
              new_agent = create(:agent, login: nil, email: agent.email)
            end

            expect(new_agent.login.sub!(new_agent.email, '')).to be_a_uuid
          end
        end

        context 'when email-as-login was used and is changed' do
          it 'updates login' do
            new_agent = create(:agent, login: nil)

            new_agent.update! email: Faker::Internet.unique.email

            expect(new_agent.login).to eq(new_agent.email)
          end

          it 'number up agent logins (1)' do
            new_agent = create(:agent, login: nil, email: agent.email)

            new_email = Faker::Internet.unique.email

            agent.update! email: new_email

            new_agent.update! email: new_email

            expect(new_agent.login).to eq("#{new_agent.email}1")
          end
        end
      end
    end

    describe '#check_name' do
      shared_examples 'preserving name' do |expected_firstname, expected_lastname|
        it 'preserves the given name' do
          expect(user).to have_attributes(firstname: expected_firstname, lastname: expected_lastname)
        end
      end

      context 'without postmaster context' do
        context 'when only lastname is present' do
          let(:user) { create(:user, firstname: '', lastname: lastname, email: Faker::Internet.unique.email) }

          context 'with all-uppercase single word' do
            let(:lastname) { 'TESTUSER' }

            it_behaves_like 'preserving name', '', 'TESTUSER'
          end

          context 'with all-lowercase single word' do
            let(:lastname) { 'testuser' }

            it_behaves_like 'preserving name', '', 'testuser'
          end

          context 'with mixed-case single word' do
            let(:lastname) { 'McTester' }

            it_behaves_like 'preserving name', '', 'McTester'
          end
        end

        context 'when only firstname is present' do
          let(:user) { create(:user, firstname: firstname, lastname: '', email: Faker::Internet.unique.email) }

          context 'with two words (splits and capitalizes via name_guess)' do
            let(:firstname) { 'perkūnas ąžuolas' }

            it_behaves_like 'preserving name', 'Perkūnas', 'Ąžuolas'
          end
        end

        context 'when both names are present' do
          let(:user) { create(:user, firstname: 'John', lastname: 'TESTUSER', email: Faker::Internet.unique.email) }

          it_behaves_like 'preserving name', 'John', 'TESTUSER'
        end
      end

      context 'with postmaster context' do
        context 'when only firstname is present' do
          let(:user) do
            ApplicationHandleInfo.use('scheduler.postmaster') do
              create(:user, firstname: firstname, lastname: '', email: Faker::Internet.unique.email)
            end
          end

          context 'with two lowercase words (splits into first/last)' do
            let(:firstname) { 'yann degran' }

            it_behaves_like 'preserving name', 'Yann', 'Degran'
          end

          context 'with two uppercase words (splits and capitalizes)' do
            let(:firstname) { 'YANN DEGRAN' }

            it_behaves_like 'preserving name', 'Yann', 'Degran'
          end

          context 'with non-ASCII characters' do
            let(:firstname) { 'perkūnas ąžuolas' }

            it_behaves_like 'preserving name', 'Perkūnas', 'Ąžuolas'
          end
        end

        context 'when both names are blank' do
          context 'with firstname.lastname email' do
            let(:user) do
              ApplicationHandleInfo.use('scheduler.postmaster') do
                create(:user, firstname: '', lastname: '', email: 'john.doe@example.com')
              end
            end

            it_behaves_like 'preserving name', 'John', 'Doe'
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
          .to change(user, :login_failed).to(0)
      end
    end

    describe '#password' do
      let(:password) { Faker::Internet.password }

      context 'when set to plaintext password' do
        it 'hashes password before saving to DB' do
          user.password = password

          expect { user.save }
            .to change { PasswordHash.crypted?(user.password) }
        end
      end

      context 'for existing user records' do
        before do
          user.update(password: password)
          allow(user).to receive(:ensured_password).and_call_original
        end

        context 'when changed to empty string' do
          it 'keeps previous password' do
            expect { user.update!(password: '') }
              .not_to change(user, :password)
          end

          it 'calls #ensured_password' do
            user.update!(password: '')

            expect(user).to have_received(:ensured_password)
          end
        end

        context 'when changed to nil' do
          it 'keeps previous password' do
            expect { user.update!(password: nil) }
              .not_to change(user, :password)
          end

          it 'calls #ensured_password' do
            user.update!(password: nil)

            expect(user).to have_received(:ensured_password)
          end
        end

        context 'when changed another attribute' do
          it 'keeps previous password' do
            expect { user.update!(email: "123#{user.email}") }
              .not_to change(user, :password)
          end

          it 'does not call #ensured_password' do
            user.update!(email: "123#{user.email}")

            expect(user).not_to have_received(:ensured_password)
          end
        end
      end

      context 'for new user records' do
        context 'when passed as an empty string' do
          let(:another_user) { create(:user, password: '') }

          it 'sets password to nil' do
            expect(another_user.password).to be_nil
          end
        end

        context 'when passed as nil' do
          let(:another_user) { create(:user, password: nil) }

          it 'sets password to nil' do
            expect(another_user.password).to be_nil
          end
        end
      end

      context 'when set to SHA2 digest (to facilitate OTRS imports)' do
        it 'does not re-hash before saving' do
          user.password = "{sha2}#{Digest::SHA2.hexdigest(password)}"

          expect { user.save }.not_to change(user, :password)
        end
      end

      context 'when set to Argon2 digest' do
        it 'does not re-hash before saving' do
          user.password = PasswordHash.crypt(password)

          expect { user.save }.not_to change(user, :password)
        end
      end

      context 'when creating two users with the same password' do
        before { user.update(password: password) }

        let(:another_user) { create(:user, password: password) }

        it 'does not generate the same password hash' do
          expect(user.password).not_to eq(another_user.password)
        end
      end

      context 'when saving a very long password' do
        let(:long_string) { "asd1ASDasd!#{Faker::Lorem.characters(number: 1_000)}" }

        it 'marks object as invalid by adding error' do
          user.update(password: long_string)
          expect(user.errors.first.full_message).to eq('Password is too long')
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
        let(:new_number)  { '1234567890' }

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
          allow(Cti::CallerId).to receive(:add).with(any_args)

          expect(Cti::CallerId.where(object: 'User', o_id: user.id).count)
            .to eq(0)

          expect { user.update(phone: new_number) }
            .not_to change { Cti::CallerId.where(object: 'User', o_id: user.id).count }

          expect(Cti::CallerId).not_to have_received(:add)
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

    describe '#preferences' do
      describe '"mail_delivery_failed{,_data}" keys' do
        before do
          user.update(
            preferences: {
              mail_delivery_failed:      true,
              mail_delivery_failed_data: Time.current
            }
          )
        end

        it 'deletes "mail_delivery_failed"' do
          expect { user.update(email: Faker::Internet.email) }
            .to change { user.preferences.key?(:mail_delivery_failed) }.to(false)
        end

        it 'leaves "mail_delivery_failed_data" untouched' do
          expect { user.update(email: Faker::Internet.email) }
            .to not_change { user.preferences[:mail_delivery_failed_data] }
        end
      end

      describe '"notification_sound" preferences' do
        it 'accepts boolean true/false on create and update, and rejects invalid values', :aggregate_failures do
          name  = SecureRandom.uuid
          roles = Role.where(name: 'Agent')

          agent1 = described_class.create!(
            login:         "agent-default-preferences-1#{name}@example.com",
            firstname:     'valid_agent_group_permission-1',
            lastname:      "Agent#{name}",
            email:         "agent-default-preferences-1#{name}@example.com",
            password:      'agentpw',
            active:        true,
            roles:         roles,
            preferences:   {
              notification_sound: {
                enabled: true,
              }
            },
            updated_by_id: 1,
            created_by_id: 1,
          )
          expect(agent1.preferences[:notification_sound][:enabled]).to be(true)

          agent2 = described_class.create!(
            login:         "agent-default-preferences-2#{name}@example.com",
            firstname:     'valid_agent_group_permission-2',
            lastname:      "Agent#{name}",
            email:         "agent-default-preferences-2#{name}@example.com",
            password:      'agentpw',
            active:        true,
            roles:         roles,
            preferences:   {
              notification_sound: {
                enabled: false,
              }
            },
            updated_by_id: 1,
            created_by_id: 1,
          )
          expect(agent2.preferences[:notification_sound][:enabled]).to be(false)

          agent3 = described_class.create!(
            login:         "agent-default-preferences-3#{name}@example.com",
            firstname:     'valid_agent_group_permission-3',
            lastname:      "Agent#{name}",
            email:         "agent-default-preferences-3#{name}@example.com",
            password:      'agentpw',
            active:        true,
            roles:         roles,
            preferences:   {
              notification_sound: {
                enabled: true,
              }
            },
            updated_by_id: 1,
            created_by_id: 1,
          )
          expect(agent3.preferences[:notification_sound][:enabled]).to be(true)

          agent3.preferences[:notification_sound][:enabled] = 'false'
          agent3.save!
          agent3.reload
          expect(agent3.preferences[:notification_sound][:enabled]).to be(false)

          agent4 = described_class.create!(
            login:         "agent-default-preferences-4#{name}@example.com",
            firstname:     'valid_agent_group_permission-4',
            lastname:      "Agent#{name}",
            email:         "agent-default-preferences-4#{name}@example.com",
            password:      'agentpw',
            active:        true,
            roles:         roles,
            preferences:   {
              notification_sound: {
                enabled: false,
              }
            },
            updated_by_id: 1,
            created_by_id: 1,
          )
          expect(agent4.preferences[:notification_sound][:enabled]).to be(false)

          agent4.preferences[:notification_sound][:enabled] = 'true'
          agent4.save!
          agent4.reload
          expect(agent4.preferences[:notification_sound][:enabled]).to be(true)

          agent4.preferences[:notification_sound][:enabled] = 'invalid'
          expect { agent4.save! }.to raise_error(Exceptions::UnprocessableContent)

          expect do
            described_class.create!(
              login:         "agent-default-preferences-5#{name}@example.com",
              firstname:     'valid_agent_group_permission-5',
              lastname:      "Agent#{name}",
              email:         "agent-default-preferences-5#{name}@example.com",
              password:      'agentpw',
              active:        true,
              roles:         roles,
              preferences:   {
                notification_sound: {
                  enabled: 'invalid string',
                }
              },
              updated_by_id: 1,
              created_by_id: 1,
            )
          end.to raise_error(Exceptions::UnprocessableContent)
        end
      end
    end

    describe '#image' do

      describe 'when value is invalid' do
        let(:value) { 'Th1515n0t4v4l1dh45h' }

        it 'prevents create' do
          expect { create(:user, image: value) }.to raise_error(Exceptions::UnprocessableContent, %r{#{value}})
        end

        it 'prevents update' do
          expect { create(:user).update!(image: value) }.to raise_error(Exceptions::UnprocessableContent, %r{#{value}})
        end
      end
    end

    describe '#image_source' do

      describe 'when value is invalid' do
        let(:value)   { 'Th1515n0t4v4l1dh45h' }
        let(:escaped) { Regexp.escape(value) }

        it 'valid create' do
          expect(create(:user, image_source: 'https://zammad.org/avatar.png').image_source).not_to be_nil
        end

        it 'removes invalid image source of create' do
          expect(create(:user, image_source: value).image_source).to be_nil
        end

        it 'removes invalid image source of update' do
          user = create(:user)
          user.update!(image_source: value)
          expect(user.image_source).to be_nil
        end
      end
    end

    describe '#email' do
      describe 'uniqueness' do
        it 'prevents creating a second user with the same email', :aggregate_failures do
          name = SecureRandom.uuid

          email1 = "admin1-role_without_email#{name}@example.com"
          admin1 = described_class.create!(
            login:         email1,
            firstname:     'Role',
            lastname:      "Admin1#{name}",
            email:         email1,
            password:      'adminpw',
            active:        true,
            roles:         Role.where(name: %w[Admin Agent]),
            updated_by_id: 1,
            created_by_id: 1,
          )
          expect(admin1.email).to eq(email1)

          expect do
            described_class.create!(
              login:         "#{email1}-1",
              firstname:     'Role',
              lastname:      "Admin1#{name}",
              email:         email1,
              password:      'adminpw',
              active:        true,
              roles:         Role.where(name: %w[Admin Agent]),
              updated_by_id: 1,
              created_by_id: 1,
            )
          end.to raise_error(ActiveRecord::RecordInvalid)

          email2 = "admin2-role_without_email#{name}@example.com"
          admin2 = described_class.create!(
            firstname:     'Role',
            lastname:      "Admin2#{name}",
            email:         email2,
            password:      'adminpw',
            active:        true,
            roles:         Role.where(name: %w[Admin Agent]),
            updated_by_id: 1,
            created_by_id: 1,
          )

          expect do
            admin2.email = email1
            admin2.save!
          end.to raise_error(ActiveRecord::RecordInvalid)
        end

        context 'when "user_email_multiple_use" setting is enabled' do
          before { Setting.set('user_email_multiple_use', true) }

          it 'allows creating a second user with the same email' do
            name = SecureRandom.uuid

            email1 = "admin1-role_without_email#{name}@example.com"
            described_class.create!(
              login:         email1,
              firstname:     'Role',
              lastname:      "Admin1#{name}",
              email:         email1,
              password:      'adminpw',
              active:        true,
              roles:         Role.where(name: %w[Admin Agent]),
              updated_by_id: 1,
              created_by_id: 1,
            )

            admin2 = described_class.create!(
              login:         "#{email1}-1",
              firstname:     'Role',
              lastname:      "Admin1#{name}",
              email:         email1,
              password:      'adminpw',
              active:        true,
              roles:         Role.where(name: %w[Admin Agent]),
              updated_by_id: 1,
              created_by_id: 1,
            )
            expect(admin2.email).to eq(email1)
          end
        end
      end

      describe 'without email' do
        context 'when login was originally set equal to the (later added/removed) email' do
          it 'generates a new login once email is cleared again', :aggregate_failures do
            name = SecureRandom.uuid

            login = "admin-role_without_email#{name}@example.com"
            email = "admin-role_without_email#{name}@example.com"
            admin = described_class.create_or_update(
              login:         login,
              firstname:     'Role',
              lastname:      "Admin#{name}",
              password:      'adminpw',
              active:        true,
              roles:         Role.where(name: %w[Admin Agent]),
              updated_by_id: 1,
              created_by_id: 1,
            )

            expect(admin.id).to be_present
            expect(admin.login).to eq(login)
            expect(admin.email).to eq('')

            admin.email = email
            admin.save!

            expect(admin.login).to eq(login)
            expect(admin.email).to eq(email)

            admin.email = ''
            admin.save!

            expect(admin.id).to be_present
            expect(admin.login).to be_present
            expect(admin.login).not_to eq(login)
            expect(admin.email).to eq('')
          end
        end

        context 'when login was originally different from the (later added/removed) email' do
          it 'keeps the original login once email is cleared again', :aggregate_failures do
            name = SecureRandom.uuid

            login = "admin-role_without_email#{name}"
            email = "admin-role_without_email#{name}@example.com"
            admin = described_class.create_or_update(
              login:         login,
              firstname:     'Role',
              lastname:      "Admin#{name}",
              password:      'adminpw',
              active:        true,
              roles:         Role.where(name: %w[Admin Agent]),
              updated_by_id: 1,
              created_by_id: 1,
            )

            expect(admin.id).to be_present
            expect(admin.login).to eq(login)
            expect(admin.email).to eq('')

            admin.email = email
            admin.save!

            expect(admin.login).to eq(login)
            expect(admin.email).to eq(email)

            admin.email = ''
            admin.save!

            expect(admin.id).to be_present
            expect(admin.login).to eq(login)
            expect(admin.email).to eq('')
          end
        end
      end
    end

    describe 'fetch_avatar_for_email', performs_jobs: true do
      it 'enqueues avatar job when creating a user with email' do
        expect { create(:user) }.to have_enqueued_job AvatarCreateJob
      end

      it 'does not enqueue avatar job when creating a user without email' do
        expect { create(:user, :without_email) }.not_to have_enqueued_job AvatarCreateJob
      end

      context 'with an existing user' do
        before do
          agent
          clear_jobs
        end

        it 'enqueues avatar job when updating a user with email' do
          expect { agent.update! email: 'avatar@example.com' }.to have_enqueued_job AvatarCreateJob
        end

        it 'does not enqueue avatar job when updating a user without email' do
          expect { agent.update! login: 'avatar_login', email: nil }.not_to have_enqueued_job AvatarCreateJob
        end

        it 'does not enqueue avatar job when updating a user having email' do
          expect { agent.update! firstname: 'no avatar update' }.not_to have_enqueued_job AvatarCreateJob
        end
      end
    end
  end

  describe 'Associations:' do
    subject(:user) { create(:agent, groups: [group_subject]) }

    let!(:group_subject) { create(:group) }

    it 'does remove references before destroy' do
      refs_known = {
        'Group'                              => { 'created_by_id' => 1, 'updated_by_id' => 0 },
        'Token'                              => { 'user_id' => 1 },
        'Ticket::Article'                    => { 'created_by_id' => 1, 'updated_by_id' => 1, 'origin_by_id' => 1 },
        'Ticket::StateType'                  => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Ticket::Article::Sender'            => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Ticket::Article::Type'              => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Ticket::Article::Flag'              => { 'created_by_id' => 0 },
        'Ticket::Priority'                   => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Ticket::SharedDraftStart'           => { 'created_by_id' => 1, 'updated_by_id' => 0 },
        'Ticket::SharedDraftZoom'            => { 'created_by_id' => 1, 'updated_by_id' => 0 },
        'Ticket::TimeAccounting'             => { 'created_by_id' => 0 },
        'Ticket::TimeAccounting::Type'       => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Ticket::State'                      => { 'created_by_id' => 1, 'updated_by_id' => 1 },
        'PostmasterFilter'                   => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'PublicLink'                         => { 'created_by_id' => 1, 'updated_by_id' => 0 },
        'User::TwoFactorPreference'          => { 'created_by_id' => 1, 'updated_by_id' => 1, 'user_id' => 1 },
        'OnlineNotification'                 => { 'user_id' => 1, 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Ticket'                             => { 'created_by_id' => 0, 'updated_by_id' => 0, 'owner_id' => 1, 'customer_id' => 3 },
        'Template'                           => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Avatar'                             => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Scheduler'                          => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Chat'                               => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'HttpLog'                            => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'EmailAddress'                       => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Taskbar'                            => { 'user_id' => 1 },
        'Sla'                                => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'UserDevice'                         => { 'user_id' => 1 },
        'Chat::Message'                      => { 'created_by_id' => 1 },
        'Chat::Agent'                        => { 'created_by_id' => 1, 'updated_by_id' => 1 },
        'Chat::Session'                      => { 'user_id' => 1, 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Tag'                                => { 'created_by_id' => 0 },
        'RecentClose'                        => { 'user_id' => 1 },
        'RecentView'                         => { 'created_by_id' => 1 },
        'KnowledgeBase::Answer::Translation' => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'LdapSource'                         => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'KnowledgeBase::Answer'              => { 'archived_by_id' => 1, 'published_by_id' => 1, 'internal_by_id' => 1 },
        'Report::Profile'                    => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Package'                            => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Job'                                => { 'created_by_id' => 0, 'updated_by_id' => 1 },
        'Store'                              => { 'created_by_id' => 0 },
        'Cti::CallerId'                      => { 'user_id' => 1 },
        'DataPrivacyTask'                    => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Trigger'                            => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Translation'                        => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'ObjectManager::Attribute'           => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'User'                               => { 'created_by_id' => 2, 'out_of_office_replacement_id' => 1, 'updated_by_id' => 2 },
        'User::OverviewSorting'              => { 'created_by_id' => 0, 'updated_by_id' => 0, 'user_id' => 1 },
        'Organization'                       => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Macro'                              => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'CoreWorkflow'                       => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Mention'                            => { 'created_by_id' => 1, 'updated_by_id' => 0, 'user_id' => 1 },
        'Channel'                            => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Role'                               => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'History'                            => { 'created_by_id' => 6 },
        'Webhook'                            => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Overview'                           => { 'created_by_id' => 1, 'updated_by_id' => 0 },
        'PGPKey'                             => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'AI::Agent'                          => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'AI::Analytics::Usage'               => { 'user_id' => 1 },
        'AI::TextTool'                       => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'ActivityStream'                     => { 'created_by_id' => 0 },
        'StatsStore'                         => { 'created_by_id' => 0 },
        'TextModule'                         => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Calendar'                           => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'UserGroup'                          => { 'user_id' => 1 },
        'Signature'                          => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Authorization'                      => { 'user_id' => 1 },
        'SystemReport'                       => { 'created_by_id' => 0 },
        'Checklist'                          => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'Checklist::Item'                    => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'ChecklistTemplate'                  => { 'created_by_id' => 0, 'updated_by_id' => 0 },
        'ChecklistTemplate::Item'            => { 'created_by_id' => 0, 'updated_by_id' => 0 },
      }

      # delete objects
      token                      = create(:token, user: user)
      online_notification        = create(:online_notification, user: user)
      taskbar                    = create(:taskbar, :with_ticket, user: user)
      user_device                = create(:user_device, user: user)
      cti_caller_id              = create(:cti_caller_id, user: user)
      authorization              = create(:twitter_authorization, user: user)
      recent_view                = create(:recent_view, created_by: user)
      avatar                     = create(:avatar, o_id: user.id)
      overview                   = create(:overview, created_by_id: user.id, user_ids: [user.id])
      mention                    = build(:mention, mentionable: create(:ticket), user: user).tap { |elem| elem.save!(validate: false) }
      mention_created_by         = build(:mention, mentionable: create(:ticket), user: create(:agent), created_by: user).tap { |elem| elem.save!(validate: false) }
      user_created_by            = create(:customer, created_by_id: user.id, updated_by_id: user.id, out_of_office_replacement_id: user.id)
      chat_session               = create(:'chat/session', user: user)
      chat_message               = create(:'chat/message', chat_session: chat_session)
      chat_message2              = create(:'chat/message', chat_session: chat_session, created_by: user)
      draft_start                = create(:ticket_shared_draft_start, created_by: user)
      draft_zoom                 = create(:ticket_shared_draft_zoom, created_by: user)
      public_link                = create(:public_link, created_by: user)
      user_two_factor_preference = create(:user_two_factor_preference, :authenticator_app, user: user)
      user_overview_sorting      = create(:'user/overview_sorting', user: user)
      recent_close               = create(:recent_close, user: user)
      ai_usage                   = create(:ai_analytics_usage, user: user)
      expect(overview.reload.user_ids).to eq([user.id])

      # create a chat agent for admin user (id=1) before agent user
      # to be sure that the data gets removed and not mapped which
      # would result in a foreign key because of the unique key on the
      # created_by_id and updated_by_id.
      create(:'chat/agent')
      chat_agent_user = create(:'chat/agent', created_by_id: user.id, updated_by_id: user.id)

      # invalid user (by email) which has been updated by the user which
      # will get deleted (#3935)
      invalid_user = build(:user, email: 'abc', created_by_id: user.id, updated_by_id: user.id)
      invalid_user.save!(validate: false)

      # move ownership objects
      group                 = create(:group, created_by_id: user.id)
      job                   = create(:job, updated_by_id: user.id)
      ticket                = create(:ticket, group: group_subject, owner: user)
      ticket_article        = create(:ticket_article, ticket: ticket, created_by_id: user.id, updated_by_id: user.id, origin_by_id: user.id)
      customer_ticket1      = create(:ticket, group: group_subject, customer: user)
      customer_ticket2      = create(:ticket, group: group_subject, customer: user)
      customer_ticket3      = create(:ticket, group: group_subject, customer: user)
      knowledge_base_answer = create(:knowledge_base_answer, archived_by_id: user.id, published_by_id: user.id, internal_by_id: user.id)
      ticket_state          = create(:ticket_state, created_by_id: user.id)
      ticket_merged_state   = Ticket::State.find_by(name: 'merged').tap { it.update!(updated_by_id: user.id) }

      refs_user = Models.references('User', user.id, true)
      expect(refs_user).to eq(refs_known)

      user.destroy

      expect { token.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { online_notification.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { taskbar.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { user_device.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { cti_caller_id.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { authorization.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { recent_view.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { avatar.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { customer_ticket1.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { customer_ticket2.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { customer_ticket3.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { chat_agent_user.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { mention.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect(mention_created_by.reload.created_by_id).not_to eq(user.id)
      expect(overview.reload.user_ids).to eq([])
      expect { chat_session.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { chat_message.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { chat_message2.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { user_two_factor_preference.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { user_overview_sorting.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { recent_close.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      expect { ai_usage.reload }.to raise_exception(ActiveRecord::RecordNotFound)

      # move ownership objects
      expect { group.reload }.to change(group, :created_by_id).to(1)
      expect { job.reload }.to change(job, :updated_by_id).to(1)
      expect { ticket.reload }.to change(ticket, :owner_id).to(1)
      expect { ticket_article.reload }
        .to change(ticket_article, :origin_by_id).to(1)
        .and change(ticket_article, :updated_by_id).to(1)
        .and change(ticket_article, :created_by_id).to(1)
      expect { knowledge_base_answer.reload }
        .to change(knowledge_base_answer, :archived_by_id).to(1)
        .and change(knowledge_base_answer, :published_by_id).to(1)
        .and change(knowledge_base_answer, :internal_by_id).to(1)
      expect { user_created_by.reload }
        .to change(user_created_by, :created_by_id).to(1)
        .and change(user_created_by, :updated_by_id).to(1)
        .and change(user_created_by, :out_of_office_replacement_id).to(1)
      expect { draft_start.reload }.to change(draft_start, :created_by_id).to(1)
      expect { draft_zoom.reload }.to change(draft_zoom, :created_by_id).to(1)
      expect { invalid_user.reload }.to change(invalid_user, :created_by_id).to(1)
      expect { public_link.reload }.to change(public_link, :created_by_id).to(1)
      expect { ticket_state.reload }.to change(ticket_state, :created_by_id).to(1)
      expect { ticket_merged_state.reload }.to change(ticket_merged_state, :updated_by_id).to(1)
    end

    it 'does delete cache after user deletion' do
      online_notification = create(:online_notification, created_by_id: user.id)
      online_notification.attributes_with_association_ids
      user.destroy
      expect(online_notification.reload.attributes_with_association_ids['created_by_id']).to eq(1)
    end

    it 'destroys associated StatsStore records on destroy (#destroy_longer_required_objects)' do
      stats_store = StatsStore.create!(stats_storable: user, key: 'some_key', data: { A: 1, B: 2 }, created_by_id: 1)

      user.destroy

      expect { stats_store.reload }.to raise_exception(ActiveRecord::RecordNotFound)
    end

    it 'does return an exception on blocking dependencies' do
      expect { user.send(:destroy_move_dependency_ownership) }.to raise_error(RuntimeError, 'Failed deleting references! Check logic for UserGroup->user_id.')
    end

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
                expect { user.save }.not_to change(user, :organization)
              end
            end

            context 'and Organization#domain_assignment is true' do
              before { organization.update(domain_assignment: true) }

              it 'is automatically set to matching Organization' do
                expect { user.save }
                  .to change(user, :organization).to(organization)
              end
            end
          end

          context 'and #email domain doesn’t match any Organization#domain' do
            before { user.assign_attributes(email: 'user@example.net') }

            let(:organization) { create(:organization, domain: 'example.com') }

            context 'and Organization#domain_assignment is true' do
              before { organization.update(domain_assignment: true) }

              it 'remains nil' do
                expect { user.save }.not_to change(user, :organization)
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
                  .not_to change(user, :organization).from(specified_organization)
              end
            end
          end
        end
      end
    end
  end

  describe 'Callbacks, Observers, & Async Transactions -' do
    describe 'System-wide agent limit checks:' do
      let(:agent_role)     { Role.lookup(name: 'Agent') }
      let(:admin_role)     { Role.lookup(name: 'Admin') }
      let(:current_agents) { described_class.with_permissions('ticket.agent') }

      describe '#validate_agent_limit_by_role' do
        context 'for Integer value of system_agent_limit' do
          context 'before exceeding the agent limit' do
            before { Setting.set('system_agent_limit', current_agents.count + 1) }

            it 'grants agent creation' do
              expect { create(:agent) }
                .to change(current_agents, :count).by(1)
            end

            it 'grants role change' do
              future_agent = create(:customer)

              expect { future_agent.roles = [agent_role] }
                .to change(current_agents, :count).by(1)
            end

            describe 'role updates' do
              let(:agent) { create(:agent) }

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

              create_list(:agent, 2)

              expect { create(:agent) }
                .to raise_error(Exceptions::UnprocessableContent)
                .and not_change(current_agents, :count)
            end

            it 'prevents role change' do
              Setting.set('system_agent_limit', current_agents.count)

              future_agent = create(:customer)

              expect { future_agent.roles = [agent_role] }
                .to raise_error(Exceptions::UnprocessableContent)
                .and not_change(current_agents, :count)
            end
          end
        end

        context 'for String value of system_agent_limit' do
          context 'before exceeding the agent limit' do
            before { Setting.set('system_agent_limit', (current_agents.count + 1).to_s) }

            it 'grants agent creation' do
              expect { create(:agent) }
                .to change(current_agents, :count).by(1)
            end

            it 'grants role change' do
              future_agent = create(:customer)

              expect { future_agent.roles = [agent_role] }
                .to change(current_agents, :count).by(1)
            end

            describe 'role updates' do
              let(:agent) { create(:agent) }

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

              create_list(:agent, 2)

              expect { create(:agent) }
                .to raise_error(Exceptions::UnprocessableContent)
                .and not_change(current_agents, :count)
            end

            it 'prevents role change' do
              Setting.set('system_agent_limit', current_agents.count.to_s)

              future_agent = create(:customer)

              expect { future_agent.roles = [agent_role] }
                .to raise_error(Exceptions::UnprocessableContent)
                .and not_change(current_agents, :count)
            end
          end

          context 'when limit was exceeded but users where removed' do
            let(:agent_1) { create(:agent) }
            let(:agent_2) { create(:agent) }

            before do
              agent_1 && agent_2
              Setting.set('system_agent_limit', current_agents.count)
            end

            it 'allows to create a new agent after destroying agents to be under the limit' do
              agent_1.destroy!
              agent_2.destroy!

              expect { create(:agent) }
                .not_to raise_error
            end
          end
        end
      end

      describe '#validate_agent_limit_by_attributes' do
        context 'for Integer value of system_agent_limit' do
          before { Setting.set('system_agent_limit', current_agents.count) }

          context 'when exceeding the agent limit' do
            it 'prevents re-activation of agents' do
              inactive_agent = create(:agent, active: false)

              expect { inactive_agent.update!(active: true) }
                .to raise_error(Exceptions::UnprocessableContent)
                .and not_change(current_agents, :count)
            end
          end
        end

        context 'for String value of system_agent_limit' do
          before { Setting.set('system_agent_limit', current_agents.count.to_s) }

          context 'when exceeding the agent limit' do
            it 'prevents re-activation of agents' do
              inactive_agent = create(:agent, active: false)

              expect { inactive_agent.update!(active: true) }
                .to raise_error(Exceptions::UnprocessableContent)
                .and not_change(current_agents, :count)
            end
          end
        end
      end
    end

    describe 'Last admin protection:' do
      before do
        described_class.with_permissions(['admin', 'admin.user']).destroy_all
      end

      it 'prevents demoting/deactivating the last admin, deactivating the Admin role, or revoking its admin permission', :aggregate_failures do
        admin_count_inital = described_class.with_permissions('admin').count
        expect(admin_count_inital).to eq(0)

        random = SecureRandom.uuid
        admin1 = described_class.create_or_update(
          login:         "1admin-role#{random}@example.com",
          firstname:     'Role',
          lastname:      "Admin#{random}",
          email:         "admin-role#{random}@example.com",
          password:      'adminpw',
          active:        true,
          roles:         Role.where(name: %w[Admin Agent]),
          updated_by_id: 1,
          created_by_id: 1,
        )

        random = SecureRandom.uuid
        admin2 = described_class.create_or_update(
          login:         "2admin-role#{random}@example.com",
          firstname:     'Role',
          lastname:      "Admin#{random}",
          email:         "admin-role#{random}@example.com",
          password:      'adminpw',
          active:        true,
          roles:         Role.where(name: %w[Admin Agent]),
          updated_by_id: 1,
          created_by_id: 1,
        )

        random = SecureRandom.uuid
        admin3 = described_class.create_or_update(
          login:         "2admin-role#{random}@example.com",
          firstname:     'Role',
          lastname:      "Admin#{random}",
          email:         "admin-role#{random}@example.com",
          password:      'adminpw',
          active:        true,
          roles:         Role.where(name: %w[Admin Agent]),
          updated_by_id: 1,
          created_by_id: 1,
        )

        admin_count_inital = described_class.with_permissions('admin').count
        expect(admin_count_inital).to eq(3)

        admin1.update!(roles: Role.where(name: %w[Agent]))

        admin_count_inital = described_class.with_permissions('admin').count
        expect(admin_count_inital).to eq(2)

        admin2.update!(roles: Role.where(name: %w[Agent]))

        admin_count_inital = described_class.with_permissions('admin').count
        expect(admin_count_inital).to eq(1)

        expect { admin3.update!(roles: Role.where(name: %w[Agent])) }
          .to raise_error(Exceptions::UnprocessableContent)

        admin_count_inital = described_class.with_permissions('admin').count
        expect(admin_count_inital).to eq(1)

        expect do
          admin3.active = false
          admin3.save!
        end.to raise_error(Exceptions::UnprocessableContent)

        expect(described_class.with_permissions('admin').count).to eq(1)

        admin_role = Role.find_by(name: 'Admin')
        expect do
          admin_role.active = false
          admin_role.save!
        end.to raise_error(Exceptions::UnprocessableContent)

        expect { admin_role.permission_revoke('admin') }.to raise_error(Exceptions::UnprocessableContent)

        expect(described_class.with_permissions('admin').count).to eq(1)
      end
    end

    describe '#ensure_roles (defaults to Role.signup_role_ids when roles are cleared)' do
      it 'resets roles to Role.signup_role_ids on empty assignment, and preserves explicitly (re)assigned roles', :aggregate_failures do
        name = SecureRandom.uuid
        admin = described_class.create_or_update(
          login:         "admin-role#{name}@example.com",
          firstname:     'Role',
          lastname:      "Admin#{name}",
          email:         "admin-role#{name}@example.com",
          password:      'adminpw',
          active:        true,
          roles:         Role.where(name: %w[Admin Agent]),
          updated_by_id: 1,
          created_by_id: 1,
        )

        customer1 = described_class.create_or_update(
          login:         "user-ensure-role1-#{name}@example.com",
          firstname:     'Role',
          lastname:      "Customer#{name}",
          email:         "user-ensure-role1-#{name}@example.com",
          password:      'customerpw',
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(customer1.role_ids.sort).to eq(Role.signup_role_ids)

        roles = Role.where(name: 'Agent')
        customer1.roles = roles
        customer1.save!

        expect(customer1.role_ids.count).to eq(1)
        expect(customer1.role_ids.first).to eq(roles.first.id)
        expect(customer1.roles.first.id).to eq(roles.first.id)

        customer1.roles = []
        customer1.save!

        expect(customer1.role_ids.sort).to eq(Role.signup_role_ids)
        customer1.destroy!

        customer2 = described_class.create_or_update(
          login:         "user-ensure-role2-#{name}@example.com",
          firstname:     'Role',
          lastname:      "Customer#{name}",
          email:         "user-ensure-role2-#{name}@example.com",
          password:      'customerpw',
          roles:         roles,
          active:        true,
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(customer2.role_ids.count).to eq(1)
        expect(customer2.role_ids.first).to eq(roles.first.id)
        expect(customer2.roles.first.id).to eq(roles.first.id)

        roles = Role.where(name: 'Admin')
        customer2.role_ids = [roles.first.id]
        customer2.save!

        expect(customer2.role_ids.count).to eq(1)
        expect(customer2.role_ids.first).to eq(roles.first.id)
        expect(customer2.roles.first.id).to eq(roles.first.id)

        customer2.roles = []
        customer2.save!

        expect(customer2.role_ids.sort).to eq(Role.signup_role_ids)
        customer2.destroy!

        customer3 = described_class.create_or_update(
          login:         "user-ensure-role2-#{name}@example.com",
          firstname:     'Role',
          lastname:      "Customer#{name}",
          email:         "user-ensure-role2-#{name}@example.com",
          password:      'customerpw',
          roles:         roles,
          active:        true,
          updated_by_id: 1,
          created_by_id: 1,
        )

        customer3.roles = Role.where(name: %w[Admin Agent])
        customer3.roles.each do |role|
          expect(role.name).not_to eq('Customer')
        end

        customer3.roles = Role.where(name: 'Admin')
        customer3.roles.each do |role|
          expect(role.name).not_to eq('Customer')
        end

        customer3.roles = Role.where(name: 'Agent')
        customer3.roles.each do |role|
          expect(role.name).not_to eq('Customer')
        end

        customer3.destroy!
        admin.destroy!
      end
    end

    describe 'Role conflicts via Role#preferences[:not]' do
      it 'raises RuntimeError when assigning mutually exclusive roles to a user', :aggregate_failures do
        test_role_1 = Role.create_or_update(
          name:          'Test1',
          note:          'To configure your system.',
          preferences:   {
            not: ['Test3'],
          },
          updated_by_id: 1,
          created_by_id: 1
        )
        test_role_2 = Role.create_or_update(
          name:          'Test2',
          note:          'To work on Tickets.',
          preferences:   {
            not: ['Test3'],
          },
          updated_by_id: 1,
          created_by_id: 1
        )
        test_role_3 = Role.create_or_update(
          name:          'Test3',
          note:          'People who create Tickets ask for help.',
          preferences:   {
            not: %w[Test1 Test2],
          },
          updated_by_id: 1,
          created_by_id: 1
        )
        test_role_4 = Role.create_or_update(
          name:          'Test4',
          note:          'Access the report area.',
          preferences:   {},
          created_by_id: 1,
          updated_by_id: 1,
        )
        name = SecureRandom.uuid

        expect do
          described_class.create_or_update(
            login:         "customer-role#{name}@example.com",
            firstname:     'Role',
            lastname:      "Customer#{name}",
            email:         "customer-role#{name}@example.com",
            password:      'customerpw',
            active:        true,
            roles:         [test_role_1, test_role_3],
            updated_by_id: 1,
            created_by_id: 1,
          )
        end.to raise_error(RuntimeError)

        expect do
          described_class.create_or_update(
            login:         "customer-role#{name}@example.com",
            firstname:     'Role',
            lastname:      "Customer#{name}",
            email:         "customer-role#{name}@example.com",
            password:      'customerpw',
            active:        true,
            roles:         [test_role_2, test_role_3],
            updated_by_id: 1,
            created_by_id: 1,
          )
        end.to raise_error(RuntimeError)

        user1 = described_class.create_or_update(
          login:         "customer-role#{name}@example.com",
          firstname:     'Role',
          lastname:      "Customer#{name}",
          email:         "customer-role#{name}@example.com",
          password:      'customerpw',
          active:        true,
          roles:         [test_role_1, test_role_2],
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(user1.role_ids).to include(test_role_1.id)
        expect(user1.role_ids).to include(test_role_2.id)
        expect(user1.role_ids).not_to include(test_role_3.id)
        expect(user1.role_ids).not_to include(test_role_4.id)

        user1 = described_class.create_or_update(
          login:         "customer-role#{name}@example.com",
          firstname:     'Role',
          lastname:      "Customer#{name}",
          email:         "customer-role#{name}@example.com",
          password:      'customerpw',
          active:        true,
          roles:         [test_role_1, test_role_4],
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(user1.role_ids).to include(test_role_1.id)
        expect(user1.role_ids).not_to include(test_role_2.id)
        expect(user1.role_ids).not_to include(test_role_3.id)
        expect(user1.role_ids).to include(test_role_4.id)

        expect do
          described_class.create_or_update(
            login:         "customer-role#{name}@example.com",
            firstname:     'Role',
            lastname:      "Customer#{name}",
            email:         "customer-role#{name}@example.com",
            password:      'customerpw',
            active:        true,
            roles:         [test_role_1, test_role_3],
            updated_by_id: 1,
            created_by_id: 1,
          )
        end.to raise_error(RuntimeError)

        expect do
          described_class.create_or_update(
            login:         "customer-role#{name}@example.com",
            firstname:     'Role',
            lastname:      "Customer#{name}",
            email:         "customer-role#{name}@example.com",
            password:      'customerpw',
            active:        true,
            roles:         [test_role_2, test_role_3],
            updated_by_id: 1,
            created_by_id: 1,
          )
        end.to raise_error(RuntimeError)

        expect(user1.role_ids).to include(test_role_1.id)
        expect(user1.role_ids).not_to include(test_role_2.id)
        expect(user1.role_ids).not_to include(test_role_3.id)
        expect(user1.role_ids).to include(test_role_4.id)
      end
    end

    describe 'Group access reflects agent active state and role changes:' do
      it "updates User.group_access('full') as agents are (de)activated or lose the Agent role", :aggregate_failures do
        name = SecureRandom.uuid
        group = Group.create!(
          name:          "ValidAgentGroupPermission-#{name}",
          active:        true,
          updated_by_id: 1,
          created_by_id: 1,
        )
        roles = Role.where(name: 'Agent')
        described_class.create_or_update(
          login:         "valid_agent_permission-1#{name}@example.com",
          firstname:     'valid_agent_group_permission-1',
          lastname:      "Agent#{name}",
          email:         "valid_agent_permission-1#{name}@example.com",
          password:      'agentpw',
          active:        true,
          roles:         roles,
          groups:        [group],
          updated_by_id: 1,
          created_by_id: 1,
        )
        agent2 = described_class.create_or_update(
          login:         "valid_agent_permission-2#{name}@example.com",
          firstname:     'valid_agent_group_permission-2',
          lastname:      "Agent#{name}",
          email:         "valid_agent_permission-2#{name}@example.com",
          password:      'agentpw',
          active:        true,
          roles:         roles,
          groups:        [group],
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(described_class.group_access(group.id, 'full').count).to eq(2)

        agent2.active = false
        agent2.save!
        expect(described_class.group_access(group.id, 'full').count).to eq(1)

        agent2.active = true
        agent2.save!
        expect(described_class.group_access(group.id, 'full').count).to eq(2)

        roles = Role.where(name: 'Customer')
        agent2.roles = roles
        agent2.save!
        expect(described_class.group_access(group.id, 'full').count).to eq(1)
      end
    end

    describe 'Touching associations on update:' do
      subject!(:user) { create(:customer) }

      let!(:organization) { create(:organization) }

      context 'when a customer gets a organization' do
        it 'touches its organization' do
          expect { user.update(organization: organization) }
            .to change { organization.reload.updated_at }
        end
      end
    end

    describe 'Cti::CallerId syncing:' do
      context 'with a #phone attribute' do
        subject(:user) { build(:user, phone: '1234567890') }

        it 'adds CallerId record on creation (via Cti::CallerId.add)' do
          expect(Cti::CallerId).to receive(:add).with(user)

          user.save
        end

        it 'does not update CallerId record on touch/update (via Cti::CallerId.add)' do
          expect(Cti::CallerId).to receive(:add).with(user)
          user.save

          expect(Cti::CallerId).not_to receive(:add).with(user)
          user.touch
        end

        it 'destroys CallerId record on deletion' do
          user.save

          expect { user.destroy }
            .to change(Cti::CallerId, :count).by(-1)
        end
      end
    end

    describe 'Cti::Log syncing:' do
      context 'with existing Log records', performs_jobs: true do
        context 'for incoming calls from an unknown number' do
          let!(:log) { create(:'cti/log', :with_preferences, from: '1234567890', direction: 'in') }

          context 'when creating a new user with that number' do
            subject(:user) { build(:user, phone: log.from) }

            it 'populates #preferences[:from] hash in all associated Log records (in a bg job)' do
              expect do
                user.save
                perform_enqueued_jobs commit_transaction: true
              end.to change { log.reload.preferences[:from]&.first }
                .to(hash_including('caller_id' => user.phone))
            end
          end

          context 'when updating a user with that number' do
            subject(:user) { create(:user) }

            it 'populates #preferences[:from] hash in all associated Log records (in a bg job)' do
              expect do
                user.update(phone: log.from)
                perform_enqueued_jobs commit_transaction: true
              end.to change { log.reload.preferences[:from]&.first }
                .to(hash_including('object' => 'User', 'o_id' => user.id))
            end
          end

          context 'when creating a new user with an empty number' do
            subject(:user) { build(:user, phone: '') }

            it 'does not modify any Log records' do
              expect do
                user.save
                perform_enqueued_jobs commit_transaction: true
              end.not_to change { log.reload.attributes }
            end
          end

          context 'when creating a new user with no number' do
            subject(:user) { build(:user, phone: nil) }

            it 'does not modify any Log records' do
              expect do
                user.save
                perform_enqueued_jobs commit_transaction: true
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
                  perform_enqueued_jobs commit_transaction: true
                end.to change { logs.map(&:reload).map { |log| log.preferences[:from] } }
                  .to(Array.new(5) { nil })
              end
            end

            context 'to an empty string' do
              it 'empties #preferences[:from] hash in all associated Log records (in a bg job)' do
                expect do
                  user.update(phone: '')
                  perform_enqueued_jobs commit_transaction: true
                end.to change { logs.map(&:reload).map { |log| log.preferences[:from] } }
                  .to(Array.new(5) { nil })
              end
            end

            context 'to nil' do
              it 'empties #preferences[:from] hash in all associated Log records (in a bg job)' do
                expect do
                  user.update(phone: nil)
                  perform_enqueued_jobs commit_transaction: true
                end.to change { logs.map(&:reload).map { |log| log.preferences[:from] } }
                  .to(Array.new(5) { nil })
              end
            end
          end

          context 'when updating attributes other than #phone' do
            it 'does not modify any Log records' do
              expect do
                user.update(mobile: '2345678901')
                perform_enqueued_jobs commit_transaction: true
              end.not_to change { logs.map { |x| x.reload.attributes } }
            end
          end
        end
      end
    end
  end

  describe 'Assign user to multiple organizations #1573' do
    context 'when importing users via csv' do
      let(:organization1) { create(:organization) }
      let(:organization2) { create(:organization) }
      let(:organization3) { create(:organization) }
      let(:organization4) { create(:organization) }
      let(:user)          { create(:agent, organization: organization1, organizations: [organization2, organization3]) }

      def csv_import(string)
        User.csv_import(
          string:       string,
          parse_params: {
            col_sep: ',',
          },
          try:          false,
          delete:       false,
        )
      end

      before do
        user
      end

      it 'does not change user on re-import' do
        expect { csv_import(described_class.csv_example) }.not_to change { user.reload.updated_at }
      end

      it 'does not change user on different organization order' do
        string = described_class.csv_example
        string.sub!(organization3.name, organization2.name)
        string.sub!(organization2.name, organization3.name)
        expect { csv_import(string) }.not_to change { user.reload.updated_at }
      end

      it 'does change user on different organizations' do
        string = described_class.csv_example
        string.sub!(organization2.name, organization4.name)
        expect { csv_import(string) }.to change { user.reload.updated_at }
      end
    end

    context 'when creating users' do
      it 'does not allow creation without primary organization but secondary organizations' do
        expect { create(:agent, organization: nil, organizations: create_list(:organization, 1)) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Secondary organizations are only allowed when the primary organization is given.')
      end

      it 'does not allow creation with more than 250 organizations' do
        expect { create(:agent, organization: create(:organization), organizations: create_list(:organization, 251)) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: More than 250 secondary organizations are not allowed.')
      end
    end
  end

  describe 'Check default agent notifications preferences' do
    context 'when creating users' do
      it 'does apply default agent notification to agent preferences' do
        user = create(:agent)
        expect(user.reload.preferences[:notification_config][:matrix]).to eq(Setting.get('ticket_agent_default_notifications'))
      end

      it 'does not apply default agent notification to customer preferences' do
        user = create(:customer)
        expect(user.reload.preferences[:notification_config]).to be_blank
      end
    end

    context 'when adding role to existing user' do
      it 'does apply default agent notification to agent preferences (without "ticket.agent" permission before)' do
        future_agent = create(:customer)

        expect { future_agent.roles = [Role.lookup(name: 'Agent')] }
          .to change { future_agent.reload.preferences.dig('notification_config', 'matrix') }
          .to Setting.get('ticket_agent_default_notifications')
      end

      it 'does not apply default agent notification to agent preferences (with "ticket.agent" permission before)' do
        agent = create(:agent)

        expect { agent.roles = [Role.lookup(name: 'Customer')] }
          .not_to change { agent.reload.preferences.dig('notification_config', 'matrix') }
      end
    end
  end

  describe 'Sanitizes name attributes for offending URLs' do
    shared_examples 'sanitizing user name attributes' do |firstname, lastname|
      it 'sanitizes user name attributes' do
        expect(user).to have_attributes(firstname: firstname, lastname: lastname)
      end
    end

    context 'with firstname attribute only' do
      let(:user) { create(:customer, firstname: value, lastname: nil, email: Faker::Internet.unique.email) }

      context 'when equaling a URL with a scheme' do
        let(:value) { 'https://zammad.org/participate' }

        it_behaves_like 'sanitizing user name attributes', 'zammad.org/participate'
      end

      context 'when equaling a URL without a scheme' do
        let(:value) { 'zammad.org' }

        it_behaves_like 'sanitizing user name attributes', 'zammad.org'
      end

      context 'when containing a URL with a scheme' do
        let(:value) { 'Click here to confirm https://zammad.org/participate then log in' }

        it_behaves_like 'sanitizing user name attributes', 'Click', 'here to confirm zammad.org/participate then log in'
      end

      context 'when containing a URL with an invalid scheme' do
        let(:value) { 'A: Testing' }

        it_behaves_like 'sanitizing user name attributes', 'A:', 'Testing'
      end
    end

    context 'with lastname attribute only' do
      let(:user) { create(:customer, firstname: nil, lastname: value, email: Faker::Internet.unique.email) }

      context 'when equaling a URL with a scheme' do
        let(:value) { 'https://zammad.org/participate' }

        it_behaves_like 'sanitizing user name attributes', nil, 'zammad.org/participate'
      end

      context 'when equaling a URL without a scheme' do
        let(:value) { 'zammad.org' }

        it_behaves_like 'sanitizing user name attributes', nil, 'zammad.org'
      end

      context 'when containing a URL with a scheme' do
        let(:value) { 'Click here to confirm https://zammad.org/participate then log in' }

        it_behaves_like 'sanitizing user name attributes', 'Click', 'here to confirm zammad.org/participate then log in'
      end
    end

    context 'with both firstname and lastname attribute' do
      let(:user) { create(:customer, firstname: firstname, lastname: lastname, email: Faker::Internet.unique.email) }

      context 'when equaling a URL with a scheme' do
        let(:firstname) { 'Click here to confirm' }
        let(:lastname)  { 'https://zammad.org/participate' }

        it_behaves_like 'sanitizing user name attributes', 'Click here to confirm', 'zammad.org/participate'
      end

      context 'when equaling a URL without a scheme' do
        let(:firstname) { 'zammad.org' }
        let(:lastname) { 'Foundation' }

        it_behaves_like 'sanitizing user name attributes', 'zammad.org', 'Foundation'
      end

      context 'when containing a URL with a scheme' do
        let(:firstname) { 'Click here to confirm' }
        let(:lastname)  { 'https://zammad.org/participate then log in' }

        it_behaves_like 'sanitizing user name attributes', 'Click here to confirm', 'zammad.org/participate then log in'
      end

      context 'when containing a URL with an invalid scheme' do
        let(:firstname) { 'Dummy R: Berlin' }
        let(:lastname)  { 'Mail' }

        it_behaves_like 'sanitizing user name attributes', 'Dummy R: Berlin', 'Mail'
      end
    end
  end

  describe 'Performance: Remove assets which are present in collection assets #5495' do
    let!(:user) { create(:user, groups: create_list(:group, 5)) }

    it 'does not deliver global assets' do
      expect(user.groups).to be_present
      expect(user.assets({}).deep_symbolize_keys.keys).not_to include(:TicketPriority, :Role, :TicketState, :Group)
    end
  end

  describe 'Prevent an organization from being both primary and secondary #5254' do
    let(:organizations) { create_list(:organization, 3) }

    it 'is not allowed to assign the same organization as primary and secondary' do
      expect { create(:user, organization_id: organizations.first.id, organization_ids: [organizations.first.id, organizations.second.id]) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Secondary organizations cannot include the primary organization.')
    end

    it 'is not allowed to add one of the secondary orgaizations as primary' do
      user = create(:user, organization: organizations.first, organizations: [organizations.second])

      expect { user.organizations << organizations.first }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Secondary organizations cannot include the primary organization.')
    end

    it 'allows to move organization from secondary to primary' do
      user = create(:user, organization: organizations.first, organizations: [organizations.second])

      expect { user.update!(organization: organizations.second, organizations: [organizations.first]) }
        .not_to raise_error
    end
  end

  describe '#all_organization_ids' do
    it 'returns empty array when user has no organizations' do
      user = create(:user, organization: nil, organization_ids: [])

      expect(user.all_organization_ids).to eq([])
    end

    it 'returns only primary organization id when user has only primary organization' do
      organization = create(:organization)
      user = create(:user, organization: organization, organization_ids: [])

      expect(user.all_organization_ids).to eq([organization.id])
    end

    it 'returns both primary and secondary organization ids' do
      organization1 = create(:organization)
      organization2 = create(:organization)
      organization3 = create(:organization)

      user = create(:user, organization: organization1, organizations: [organization2, organization3])

      expect(user.all_organization_ids).to contain_exactly(organization1.id, organization2.id, organization3.id)
    end
  end

  describe 'Legacy scenarios (migrated from test/unit/user_test.rb)' do
    describe 'creating and updating users with edge-case firstname/lastname/email values' do
      let(:tests) do
        [
          {
            name:          '#1 - simple create',
            create:        {
              firstname:     'Firstname',
              lastname:      'Lastname',
              email:         'some@example.com',
              login:         'some@example.com',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              image:     nil,
              fullname:  'Firstname Lastname',
              email:     'some@example.com',
              login:     'some@example.com',
            },
          },
          {
            name:          '#2 - simple create - no lastname',
            create:        {
              firstname:     'Firstname Lastname',
              lastname:      '',
              email:         'some@example.com',
              login:         'some@example.com',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              image:     nil,
              email:     'some@example.com',
              login:     'some@example.com',
            },
          },
          {
            name:          '#3 - simple create - no firstname',
            create:        {
              firstname:     '',
              lastname:      'Firstname Lastname',
              email:         'some@example.com',
              login:         'some@example.com',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              image:     nil,
              email:     'some@example.com',
              login:     'some@example.com',
            },
          },
          {
            name:          '#4 - simple create - nil as lastname',
            create:        {
              firstname:     'Firstname Lastname',
              lastname:      '',
              email:         'some@example.com',
              login:         'some@example.com',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              image:     nil,
              email:     'some@example.com',
              login:     'some@example.com',
            },
          },
          {
            name:          '#5 - simple create - no lastname, firstname with ","',
            create:        {
              firstname:     'Lastname, Firstname',
              lastname:      '',
              email:         'some@example.com',
              login:         'some@example.com',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              email:     'some@example.com',
              login:     'some@example.com',
            },
          },
          {
            name:          '#6 - simple create - no lastname/firstname',
            create:        {
              firstname:     '',
              lastname:      '',
              email:         'firstname.lastname@example.com',
              login:         'login-1',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              fullname:  'Firstname Lastname',
              email:     'firstname.lastname@example.com',
              login:     'login-1',
            },
          },
          {
            name:          '#7 - simple create - no lastname/firstnam',
            create:        {
              firstname:     '',
              lastname:      '',
              email:         'FIRSTNAME.lastname@example.com',
              login:         'login-2',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              email:     'firstname.lastname@example.com',
              login:     'login-2',
            },
          },
          {
            name:          '#8 - simple create - nill as fristname and lastname',
            create:        {
              firstname:     '',
              lastname:      '',
              email:         'FIRSTNAME.lastname@example.com',
              login:         'login-3',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              email:     'firstname.lastname@example.com',
              login:     'login-3',
            },
          },
          {
            name:          '#11 - update create with login/email check',
            create:        {
              firstname:     '',
              lastname:      '',
              email:         'caoyaoewfzfw@21222cn.com',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: '',
              lastname:  '',
              fullname:  'caoyaoewfzfw@21222cn.com',
              email:     'caoyaoewfzfw@21222cn.com',
              login:     'caoyaoewfzfw@21222cn.com',
            },
            update:        {
              email: 'caoyaoewfzfw@212224cn.com',
            },
            update_verify: {
              firstname: '',
              lastname:  '',
              email:     'caoyaoewfzfw@212224cn.com',
              fullname:  'caoyaoewfzfw@212224cn.com',
              login:     'caoyaoewfzfw@212224cn.com',
            }
          },
          {
            name:          '#12 - update create with login/email check',
            create:        {
              firstname:     'Firstname',
              lastname:      'Lastname',
              email:         'some_tEst11@example.com',
              updated_by_id: 1,
              created_by_id: 1,
            },
            create_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              fullname:  'Firstname Lastname',
              email:     'some_test11@example.com',
            },
            update:        {
              email: 'some_Test11-1@example.com',
            },
            update_verify: {
              firstname: 'Firstname',
              lastname:  'Lastname',
              email:     'some_test11-1@example.com',
              fullname:  'Firstname Lastname',
              login:     'some_test11-1@example.com',
            }
          },
        ]
      end

      around do |example|
        default_disable_in_test_env = Service::Image::Zammad.const_get(:DISABLE_IN_TEST_ENV)
        silence_warnings { Service::Image::Zammad.const_set(:DISABLE_IN_TEST_ENV, false) }

        example.run

        silence_warnings { Service::Image::Zammad.const_set(:DISABLE_IN_TEST_ENV, default_disable_in_test_env) }
      end

      it 'derives fullname/firstname/lastname/email/login per test case', :aggregate_failures do
        tests.each do |test|
          user = described_class.find_by(login: test[:create][:login])
          user&.destroy!

          user = described_class.create!(test[:create])

          test[:create_verify].each do |key, value|
            next if key == :image_md5

            if user.respond_to?(key)
              result = user.send(key)
              if value.nil?
                expect(result).to be_nil, "create check #{key} in (#{test[:name]})"
              else
                expect(result).to eq(value), "create check #{key} in (#{test[:name]})"
              end
            else
              expect(user[key]).to eq(value), "create check #{key} in (#{test[:name]})"
            end
          end

          if test[:update]
            user.update!(test[:update])

            test[:update_verify].each do |key, value|
              next if key == :image_md5

              if user.respond_to?(key)
                expect(user.send(key)).to eq(value), "update check #{key} in (#{test[:name]})"
              else
                expect(user[key]).to eq(value), "update check #{key} in (#{test[:name]})"
              end
            end
          end

          user.destroy!
        end
      end
    end

    describe 'names and emails with unusual whitespace characters' do
      it 'strips various kinds of surrounding/embedded whitespace from firstname/lastname/email', :aggregate_failures do
        name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
        email = "customer_email#{name}@example.com"
        customer = described_class.create!(
          firstname:     'Role',
          lastname:      "Customer#{name}",
          email:         " #{email} ",
          password:      'customerpw',
          active:        true,
          roles:         Role.where(name: %w[Customer]),
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(customer).to be_present
        expect(customer.email).to eq(email)
        customer.destroy!

        name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
        email = "customer_email#{name}@example.com"
        customer = described_class.create!(
          firstname:     "\u{00a0}\u{00a0}Role",
          lastname:      "Customer#{name} \u{00a0}",
          email:         "\u{00a0}#{email}\u{00a0}",
          password:      'customerpw',
          active:        true,
          roles:         Role.where(name: %w[Customer]),
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(customer).to be_present
        expect(customer.firstname).to eq('Role')
        expect(customer.lastname).to eq("Customer#{name}")
        expect(customer.email).to eq(email)
        customer.destroy!

        name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
        email = "customer_email#{name}@example.com"
        customer = described_class.create!(
          firstname:     "\u{200B}\u{200B}Role",
          lastname:      "Customer#{name} \u{200B}",
          email:         "\u{200B}#{email}\u{200B}",
          password:      'customerpw',
          active:        true,
          roles:         Role.where(name: %w[Customer]),
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(customer).to be_present
        expect(customer.firstname).to eq('Role')
        expect(customer.lastname).to eq("Customer#{name}")
        expect(customer.email).to eq(email)
        customer.destroy!

        name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
        email = "customer_email#{name}@example.com"
        customer = described_class.create!(
          firstname:     "\u{200B}\u{200B}Role\u{00a0}",
          lastname:      "\u{00a0}\u{00a0}Customer#{name} \u{200B}",
          email:         "\u{200B}#{email}\u{200B}",
          password:      'customerpw',
          active:        true,
          roles:         Role.where(name: %w[Customer]),
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(customer).to be_present
        expect(customer.firstname).to eq('Role')
        expect(customer.lastname).to eq("Customer#{name}")
        expect(customer.email).to eq(email)
        customer.destroy!

        name = "#{Time.zone.now.to_i}-#{SecureRandom.uuid}"
        email = "customer_email#{name}@example.com"
        customer = described_class.create!(
          firstname:     "\u{200a}\u{200b}\u{202F}\u{205F}Role\u{2007}\u{2008}",
          lastname:      "\u{00a0}\u{00a0}Customer#{name}\u{3000}\u{FEFF}\u{2000}",
          email:         "\u{200B}#{email}\u{200B}\u{2007}\u{2008}",
          password:      'customerpw',
          active:        true,
          roles:         Role.where(name: %w[Customer]),
          updated_by_id: 1,
          created_by_id: 1,
        )
        expect(customer).to be_present
        expect(customer.firstname).to eq('Role')
        expect(customer.lastname).to eq("Customer#{name}")
        expect(customer.email).to eq(email)
        customer.destroy!
      end
    end
  end
end
