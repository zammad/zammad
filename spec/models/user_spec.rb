# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/has_groups_examples'
require 'models/concerns/has_history_examples'
require 'models/concerns/has_roles_examples'
require 'models/concerns/has_groups_permissions_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_image_sanitized_note_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/has_object_manager_attributes_examples'
require 'models/user/can_lookup_search_index_attributes_examples'
require 'models/user/performs_geo_lookup_examples'
require 'models/concerns/has_taskbars_examples'

RSpec.describe User, type: :model do
  subject(:user) { create(:user) }

  let(:customer) { create(:customer) }
  let(:agent)    { create(:agent) }
  let(:admin)    { create(:admin) }

  it_behaves_like 'ApplicationModel', can_assets: { associations: :organization }
  it_behaves_like 'HasGroups', group_access_factory: :agent
  it_behaves_like 'HasHistory'
  it_behaves_like 'HasRoles', group_access_factory: :agent
  it_behaves_like 'HasXssSanitizedNote', model_factory: :user
  it_behaves_like 'HasImageSanitizedNote', model_factory: :user
  it_behaves_like 'HasGroups and Permissions', group_access_no_permission_factory: :user
  it_behaves_like 'CanBeImported'
  it_behaves_like 'HasObjectManagerAttributes'
  it_behaves_like 'CanLookupSearchIndexAttributes'
  it_behaves_like 'HasTaskbars'
  it_behaves_like 'UserPerformsGeoLookup'

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
  end

  describe 'Instance methods:' do

    describe '#out_of_office?' do
      context 'without any out_of_office_* attributes set' do
        it 'returns false' do
          expect(agent.out_of_office?).to be(false)
        end
      end

      context 'with valid #out_of_office_* attributes' do
        before do
          agent.update(
            out_of_office_start_at:       Time.current.yesterday,
            out_of_office_end_at:         Time.current.tomorrow,
            out_of_office_replacement_id: 1
          )
        end

        context 'but #out_of_office: false' do
          before { agent.update(out_of_office: false) }

          it 'returns false' do
            expect(agent.out_of_office?).to be(false)
          end
        end

        context 'and #out_of_office: true' do
          before { agent.update(out_of_office: true) }

          it 'returns true' do
            expect(agent.out_of_office?).to be(true)
          end

          context 'after the #out_of_office_end_at time has passed' do
            before { travel 2.days  }

            it 'returns false (even though #out_of_office has not changed)' do
              expect(agent.out_of_office).to be(true)
              expect(agent.out_of_office?).to be(false)
            end
          end
        end
      end

      context 'date range is inclusive' do
        before do
          freeze_time

          agent.update(
            out_of_office:                true,
            out_of_office_start_at:       1.day.from_now.to_date,
            out_of_office_end_at:         1.week.from_now.to_date,
            out_of_office_replacement_id: 1
          )
        end

        it 'today in office' do
          expect(agent).not_to be_out_of_office
        end

        it 'tomorrow not in office' do
          travel 1.day
          expect(agent).to be_out_of_office
        end

        it 'after 7 days not in office' do
          travel 7.days
          expect(agent).to be_out_of_office
        end

        it 'after 8 days in office' do
          travel 8.days
          expect(agent).not_to be_out_of_office
        end
      end

      # https://github.com/zammad/zammad/issues/3590
      context 'when setting the same date' do
        before do
          freeze_time

          target_date = 1.day.from_now.to_date
          agent.update(
            out_of_office:                true,
            out_of_office_start_at:       target_date,
            out_of_office_end_at:         target_date,
            out_of_office_replacement_id: 1
          )
        end

        it 'agent is out of office tomorrow' do
          travel 1.day
          expect(agent).to be_out_of_office
        end

        it 'agent is not out of office the day after tomorrow' do
          travel 2.days
          expect(agent).not_to be_out_of_office
        end

        it 'agent is not out of office today' do
          expect(agent).not_to be_out_of_office
        end

        context 'given it respects system time zone' do
          before do
            travel_to Time.current.end_of_day
          end

          it 'agent is in office if in UTC' do
            expect(agent).not_to be_out_of_office
          end

          it 'agent is out of office if ahead of UTC' do
            travel_to Time.current.end_of_day
            Setting.set('timezone_default', 'Europe/Vilnius')

            expect(agent).to be_out_of_office
          end
        end
      end
    end

    describe '#out_of_office_agent' do
      it { is_expected.to respond_to(:out_of_office_agent) }

      context 'when user has no designated substitute' do
        it 'returns nil' do
          expect(user.out_of_office_agent).to be_nil
        end
      end

      context 'when user has designated substitute' do
        subject(:user) do
          create(:user,
                 out_of_office:                out_of_office,
                 out_of_office_start_at:       Time.zone.yesterday,
                 out_of_office_end_at:         Time.zone.tomorrow,
                 out_of_office_replacement_id: substitute.id,)
        end

        let(:substitute) { create(:user) }

        context 'but is not out of office' do
          let(:out_of_office) { false }

          it 'returns nil' do
            expect(user.out_of_office_agent).to be_nil
          end
        end

        context 'and is out of office' do
          let(:out_of_office) { true }

          it 'returns the designated substitute' do
            expect(user.out_of_office_agent).to eq(substitute)
          end
        end

        context 'with recursive out of office structure' do
          let(:out_of_office) { true }
          let(:substitute) do
            create(:user,
                   out_of_office:                out_of_office,
                   out_of_office_start_at:       Time.zone.yesterday,
                   out_of_office_end_at:         Time.zone.tomorrow,
                   out_of_office_replacement_id: user_active.id,)
          end
          let!(:user_active) { create(:user) }

          it 'returns the designated substitute recursive' do
            expect(user.out_of_office_agent).to eq(user_active)
          end
        end

        context 'with recursive out of office structure with a endless loop' do
          let(:out_of_office) { true }
          let(:substitute) do
            create(:user,
                   out_of_office:                out_of_office,
                   out_of_office_start_at:       Time.zone.yesterday,
                   out_of_office_end_at:         Time.zone.tomorrow,
                   out_of_office_replacement_id: user_active.id,)
          end
          let!(:user_active) do
            create(:user,
                   out_of_office:                out_of_office,
                   out_of_office_start_at:       Time.zone.yesterday,
                   out_of_office_end_at:         Time.zone.tomorrow,
                   out_of_office_replacement_id: agent.id,)
          end

          before do
            user_active.update(out_of_office_replacement_id: substitute.id)
          end

          it 'returns the designated substitute recursive with a endless loop' do
            expect(user.out_of_office_agent).to eq(substitute)
          end
        end

        context 'with stack depth exceeding limit' do
          let(:replacement_chain) do
            user = create(:agent)

            14
              .times
              .each_with_object([user]) do |_, memo|
                memo << create(:agent, :ooo, ooo_agent: memo.last)
              end
              .reverse
          end

          let(:ids_executed) { [] }

          before do
            allow_any_instance_of(described_class).to receive(:out_of_office_agent).and_wrap_original do |method, *args|
              ids_executed << method.receiver.id
              method.call(*args)
            end

            allow(Rails.logger).to receive(:warn)
          end

          it 'returns the last agent at the limit' do
            expect(replacement_chain.first.out_of_office_agent).to eq replacement_chain[10]
          end

          it 'does not evaluate element beyond the limit' do
            user_beyond_limit = replacement_chain[11]

            replacement_chain.first.out_of_office_agent

            expect(ids_executed).not_to include(user_beyond_limit.id)
          end

          it 'does evaluate element within the limit' do
            user_within_limit = replacement_chain[5]

            replacement_chain.first.out_of_office_agent

            expect(ids_executed).to include(user_within_limit.id)
          end

          it 'logs error below the limit' do
            replacement_chain.first.out_of_office_agent

            expect(Rails.logger).to have_received(:warn).with(%r{#{Regexp.escape('Found more than 10 replacement levels for agent')}})
          end

          it 'does not logs warn within the limit' do
            replacement_chain[10].out_of_office_agent

            expect(Rails.logger).not_to have_received(:warn)
          end
        end
      end
    end

    describe '#out_of_office_agent_of' do
      context 'when no other agents are out-of-office' do
        it 'returns an empty ActiveRecord::Relation' do
          expect(agent.out_of_office_agent_of)
            .to be_an(ActiveRecord::Relation)
            .and be_empty
        end
      end

      context 'when designated as the substitute' do
        let!(:agent_on_holiday) do
          create(
            :agent,
            out_of_office_start_at:       Time.current.yesterday,
            out_of_office_end_at:         Time.current.tomorrow,
            out_of_office_replacement_id: agent.id,
            out_of_office:                out_of_office
          )
        end

        context 'of an in-office agent' do
          let(:out_of_office) { false }

          it 'returns an empty ActiveRecord::Relation' do
            expect(agent.out_of_office_agent_of)
              .to be_an(ActiveRecord::Relation)
              .and be_empty
          end
        end

        context 'of an out-of-office agent' do
          let(:out_of_office) { true }

          it 'returns an ActiveRecord::Relation including that agent' do
            expect(agent.out_of_office_agent_of)
              .to match_array([agent_on_holiday])
          end
        end

        context 'when inherited' do
          let(:out_of_office) { true }
          let!(:agent_on_holiday_sub) do
            create(
              :agent,
              out_of_office_start_at:       Time.current.yesterday,
              out_of_office_end_at:         Time.current.tomorrow,
              out_of_office_replacement_id: agent_on_holiday.id,
              out_of_office:                out_of_office
            )
          end

          it 'returns an ActiveRecord::Relation including both agents' do
            expect(agent.out_of_office_agent_of)
              .to match_array([agent_on_holiday, agent_on_holiday_sub])
          end
        end

        context 'when inherited endless loop' do
          let(:out_of_office) { true }
          let!(:agent_on_holiday_sub) do
            create(
              :agent,
              out_of_office_start_at:       Time.current.yesterday,
              out_of_office_end_at:         Time.current.tomorrow,
              out_of_office_replacement_id: agent_on_holiday.id,
              out_of_office:                out_of_office
            )
          end
          let!(:agent_on_holiday_sub2) do
            create(
              :agent,
              out_of_office_start_at:       Time.current.yesterday,
              out_of_office_end_at:         Time.current.tomorrow,
              out_of_office_replacement_id: agent_on_holiday_sub.id,
              out_of_office:                out_of_office
            )
          end

          before do
            agent_on_holiday_sub.update(out_of_office_replacement_id: agent_on_holiday_sub2.id)
          end

          it 'returns an ActiveRecord::Relation including both agents referencing each other' do
            expect(agent_on_holiday_sub.out_of_office_agent_of)
              .to match_array([agent_on_holiday_sub, agent_on_holiday_sub2])
          end
        end
      end
    end

    describe '#by_reset_token' do
      subject(:user) { token.user }

      let(:token) { create(:token_password_reset) }

      context 'with a valid token' do
        it 'returns the matching user' do
          expect(described_class.by_reset_token(token.name)).to eq(user)
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
        expect { described_class.password_reset_via_token(token.name, Faker::Internet.password) }
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
          token = result[:token].name
          expect(described_class.admin_password_auth_via_token(token)).to match(user)
        end

        it 'destroys token' do
          result = described_class.admin_password_auth_new_token(user.login)
          token = result[:token].name
          expect { described_class.admin_password_auth_via_token(token) }.to change(Token, :count).by(-1)
        end
      end
    end

    describe '#permissions' do
      let(:user)        { create(:agent).tap { |u| u.roles = [u.roles.first] } }
      let(:role)        { user.roles.first }
      let(:permissions) { role.permissions }

      it 'is a simple association getter' do
        expect(user.permissions).to match_array(permissions)
      end

      context 'for inactive permissions' do
        before { permissions.first.update(active: false) }

        it 'omits them from the returned hash' do
          expect(user.permissions).not_to include(permissions.first)
        end
      end

      context 'for permissions on inactive roles' do
        before { role.update(active: false) }

        it 'omits them from the returned hash' do
          expect(user.permissions).not_to include(*role.permissions)
        end
      end
    end

    describe '#permissions?' do
      subject(:user) { create(:user, roles: [role]) }

      let(:role) { create(:role, permissions: [permission]) }
      let(:permission) { create(:permission, name: permission_name) }

      context 'with privileges for a root permission (e.g., "foo", not "foo.bar")' do
        let(:permission_name) { 'foo' }

        context 'when given that exact permission' do
          it 'returns true' do
            expect(user.permissions?('foo')).to be(true)
          end
        end

        context 'when given an active sub-permission' do
          before { create(:permission, name: 'foo.bar') }

          it 'returns true' do
            expect(user.permissions?('foo.bar')).to be(true)
          end
        end

        describe 'chain-of-ancestry quirk' do
          context 'when given an inactive sub-permission' do
            before { create(:permission, name: 'foo.bar.baz', active: false) }

            it 'returns false, even with active ancestors' do
              expect(user.permissions?('foo.bar.baz')).to be(false)
            end
          end

          context 'when given a sub-permission that does not exist' do
            before { create(:permission, name: 'foo.bar', active: false) }

            it 'can return true, even with inactive ancestors' do
              expect(user.permissions?('foo.bar.baz')).to be(true)
            end
          end
        end

        context 'when given a glob' do
          context 'matching that permission' do
            it 'returns true' do
              expect(user.permissions?('foo.*')).to be(true)
            end
          end

          context 'NOT matching that permission' do
            it 'returns false' do
              expect(user.permissions?('bar.*')).to be(false)
            end
          end
        end
      end

      context 'with privileges for a sub-permission (e.g., "foo.bar", not "foo")' do
        let(:permission_name) { 'foo.bar' }

        context 'when given that exact sub-permission' do
          it 'returns true' do
            expect(user.permissions?('foo.bar')).to be(true)
          end

          context 'but the permission is inactive' do
            before { permission.update(active: false) }

            it 'returns false' do
              expect(user.permissions?('foo.bar')).to be(false)
            end
          end
        end

        context 'when given a sibling sub-permission' do
          let(:sibling_permission) { create(:permission, name: 'foo.baz') }

          context 'that exists' do
            before { sibling_permission }

            it 'returns false' do
              expect(user.permissions?('foo.baz')).to be(false)
            end
          end

          context 'that does not exist' do
            it 'returns false' do
              expect(user.permissions?('foo.baz')).to be(false)
            end
          end
        end

        context 'when given the parent permission' do
          it 'returns false' do
            expect(user.permissions?('foo')).to be(false)
          end
        end

        context 'when given a glob' do
          context 'matching that sub-permission' do
            it 'returns true' do
              expect(user.permissions?('foo.*')).to be(true)
            end

            context 'but the permission is inactive' do
              before { permission.update(active: false) }

              it 'returns false' do
                expect(user.permissions?('foo.*')).to be(false)
              end
            end
          end

          context 'NOT matching that sub-permission' do
            it 'returns false' do
              expect(user.permissions?('bar.*')).to be(false)
            end
          end
        end
      end
    end

    describe '#permissions_with_child_ids' do
      context 'with privileges for a root permission (e.g., "foo", not "foo.bar")' do
        subject(:user) { create(:user, roles: [role]) }

        let(:role)                       { create(:role, permissions: [permission]) }
        let!(:permission)                { create(:permission, name: 'foo') }
        let!(:child_permission)          { create(:permission, name: 'foo.bar') }
        let!(:inactive_child_permission) { create(:permission, name: 'foo.baz', active: false) }

        it 'includes the IDs of user’s explicit permissions' do
          expect(user.permissions_with_child_ids)
            .to include(permission.id)
        end

        it 'includes the IDs of user’s active sub-permissions' do
          expect(user.permissions_with_child_ids)
            .to include(child_permission.id)
            .and not_include(inactive_child_permission.id)
        end
      end
    end

    describe '#permissions_with_child_names' do
      context 'with privileges for a root permission (e.g., "foo", not "foo.bar")' do
        subject(:user) { create(:user, roles: [role]) }

        let(:role) { create(:role, permissions: [permission]) }
        let!(:permission)                { create(:permission, name: 'foo') }
        let!(:child_permission)          { create(:permission, name: 'foo.bar') }
        let!(:inactive_child_permission) { create(:permission, name: 'foo.baz', active: false) }

        it 'includes the names of user’s explicit permissions' do
          expect(user.permissions_with_child_names)
            .to include(permission.name)
        end

        it 'includes the names of user’s active sub-permissions' do
          expect(user.permissions_with_child_names)
            .to include(child_permission.name)
            .and not_include(inactive_child_permission.name)
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
      let(:agent) { create(:agent) }

      it 'does use the origin login' do
        new_agent = create(:agent)
        expect(new_agent.login).not_to end_with('1')
      end

      it 'does number up agent logins (1)' do
        new_agent = create(:agent, login: agent.login)
        expect(new_agent.login).to eq("#{agent.login}1")
      end

      it 'does number up agent logins (5)' do
        new_agent = create(:agent, login: agent.login)
        4.times do
          new_agent = create(:agent, login: agent.login)
        end

        expect(new_agent.login).to eq("#{agent.login}5")
      end

      it 'does backup with uuid in cases of many duplicates' do
        new_agent = create(:agent, login: agent.login)
        20.times do
          new_agent = create(:agent, login: agent.login)
        end

        expect(new_agent.login.sub!(agent.login, '')).to be_a_uuid
      end
    end

    describe '#check_name' do
      it 'guesses user first/last name with non-ASCII characters' do
        user = create(:user, firstname: 'perkūnas ąžuolas', lastname: '')

        expect(user).to have_attributes(firstname: 'Perkūnas', lastname: 'Ąžuolas')
      end
    end
  end

  describe 'Attributes:' do
    describe '#out_of_office' do
      context 'with #out_of_office_start_at: nil' do
        before { agent.update(out_of_office_start_at: nil, out_of_office_end_at: Time.current) }

        it 'cannot be set to true' do
          expect { agent.update(out_of_office: true) }
            .to raise_error(Exceptions::UnprocessableEntity)
        end
      end

      context 'with #out_of_office_end_at: nil' do
        before { agent.update(out_of_office_start_at: Time.current, out_of_office_end_at: nil) }

        it 'cannot be set to true' do
          expect { agent.update(out_of_office: true) }
            .to raise_error(Exceptions::UnprocessableEntity)
        end
      end

      context 'when #out_of_office_start_at is AFTER #out_of_office_end_at' do
        before { agent.update(out_of_office_start_at: Time.current.tomorrow, out_of_office_end_at: Time.current.next_month) }

        it 'cannot be set to true' do
          expect { agent.update(out_of_office: true) }
            .to raise_error(Exceptions::UnprocessableEntity)
        end
      end

      context 'when #out_of_office_start_at is AFTER Time.current' do
        before { agent.update(out_of_office_start_at: Time.current.tomorrow, out_of_office_end_at: Time.current.yesterday) }

        it 'cannot be set to true' do
          expect { agent.update(out_of_office: true) }
            .to raise_error(Exceptions::UnprocessableEntity)
        end
      end

      context 'when #out_of_office_end_at is BEFORE Time.current' do
        before { agent.update(out_of_office_start_at: Time.current.last_month, out_of_office_end_at: Time.current.yesterday) }

        it 'cannot be set to true' do
          expect { agent.update(out_of_office: true) }
            .to raise_error(Exceptions::UnprocessableEntity)
        end
      end
    end

    describe '#out_of_office_replacement_id' do
      it 'cannot be set to invalid user ID' do
        expect { agent.update(out_of_office_replacement_id: described_class.pluck(:id).max.next) }
          .to raise_error(ActiveRecord::InvalidForeignKey)
      end

      it 'can be set to a valid user ID' do
        expect { agent.update(out_of_office_replacement_id: 1) }
          .not_to raise_error
      end
    end

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

          expect(user.errors).to satisfy { |errors| errors.any? { |error| error.message.first.include?('Invalid password') } }
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
          allow(Cti::CallerId).to receive(:build).with(any_args)

          expect(Cti::CallerId.where(object: 'User', o_id: user.id).count)
            .to eq(0)

          expect { user.update(phone: new_number) }
            .not_to change { Cti::CallerId.where(object: 'User', o_id: user.id).count }

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
    end

    describe '#image' do

      describe 'when value is invalid' do
        let(:value) { 'Th1515n0t4v4l1dh45h' }

        it 'prevents create' do
          expect { create(:user, image: value) }.to raise_error(Exceptions::UnprocessableEntity, %r{#{value}})
        end

        it 'prevents update' do
          expect { create(:user).update!(image: value) }.to raise_error(Exceptions::UnprocessableEntity, %r{#{value}})
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
      refs_known = { 'Group'                              => { 'created_by_id' => 1, 'updated_by_id' => 0 },
                     'Token'                              => { 'user_id' => 1 },
                     'Ticket::Article'                    =>
                                                             { 'created_by_id' => 1, 'updated_by_id' => 1, 'origin_by_id' => 1 },
                     'Ticket::StateType'                  => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'Ticket::Article::Sender'            => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'Ticket::Article::Type'              => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'Ticket::Article::Flag'              => { 'created_by_id' => 0 },
                     'Ticket::Priority'                   => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'Ticket::SharedDraftStart'           => { 'created_by_id' => 1, 'updated_by_id' => 0 },
                     'Ticket::SharedDraftZoom'            => { 'created_by_id' => 1, 'updated_by_id' => 0 },
                     'Ticket::TimeAccounting'             => { 'created_by_id' => 0 },
                     'Ticket::State'                      => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'Ticket::Flag'                       => { 'created_by_id' => 0 },
                     'PostmasterFilter'                   => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'PublicLink'                         => { 'created_by_id' => 1, 'updated_by_id' => 0 },
                     'OnlineNotification'                 => { 'user_id' => 1, 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'Ticket'                             =>
                                                             { 'created_by_id' => 0, 'updated_by_id' => 0, 'owner_id' => 1, 'customer_id' => 3 },
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
                     'RecentView'                         => { 'created_by_id' => 1 },
                     'KnowledgeBase::Answer::Translation' =>
                                                             { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'LdapSource'                         => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'KnowledgeBase::Answer'              =>
                                                             { 'archived_by_id' => 1, 'published_by_id' => 1, 'internal_by_id' => 1 },
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
                     'ActivityStream'                     => { 'created_by_id' => 0 },
                     'StatsStore'                         => { 'created_by_id' => 0 },
                     'TextModule'                         => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'Calendar'                           => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'UserGroup'                          => { 'user_id' => 1 },
                     'Signature'                          => { 'created_by_id' => 0, 'updated_by_id' => 0 },
                     'Authorization'                      => { 'user_id' => 1 } }

      # delete objects
      token                 = create(:token, user: user)
      online_notification   = create(:online_notification, user: user)
      taskbar               = create(:taskbar, user: user)
      user_device           = create(:user_device, user: user)
      cti_caller_id         = create(:cti_caller_id, user: user)
      authorization         = create(:twitter_authorization, user: user)
      recent_view           = create(:recent_view, created_by: user)
      avatar                = create(:avatar, o_id: user.id)
      overview              = create(:overview, created_by_id: user.id, user_ids: [user.id])
      mention               = create(:mention, mentionable: create(:ticket), user: user)
      mention_created_by    = create(:mention, mentionable: create(:ticket), user: create(:agent), created_by: user)
      user_created_by       = create(:customer, created_by_id: user.id, updated_by_id: user.id, out_of_office_replacement_id: user.id)
      chat_session          = create(:'chat/session', user: user)
      chat_message          = create(:'chat/message', chat_session: chat_session)
      chat_message2         = create(:'chat/message', chat_session: chat_session, created_by: user)
      draft_start           = create(:ticket_shared_draft_start, created_by: user)
      draft_zoom            = create(:ticket_shared_draft_zoom, created_by: user)
      public_link           = create(:public_link, created_by: user)
      user_overview_sorting = create(:'user/overview_sorting', user: user)
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
      expect { user_overview_sorting.reload }.to raise_exception(ActiveRecord::RecordNotFound)

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
    end

    it 'does delete cache after user deletion' do
      online_notification = create(:online_notification, created_by_id: user.id)
      online_notification.attributes_with_association_ids
      user.destroy
      expect(online_notification.reload.attributes_with_association_ids['created_by_id']).to eq(1)
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
                .to raise_error(Exceptions::UnprocessableEntity)
                .and not_change(current_agents, :count)
            end

            it 'prevents role change' do
              Setting.set('system_agent_limit', current_agents.count)

              future_agent = create(:customer)

              expect { future_agent.roles = [agent_role] }
                .to raise_error(Exceptions::UnprocessableEntity)
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
                .to raise_error(Exceptions::UnprocessableEntity)
                .and not_change(current_agents, :count)
            end

            it 'prevents role change' do
              Setting.set('system_agent_limit', current_agents.count.to_s)

              future_agent = create(:customer)

              expect { future_agent.roles = [agent_role] }
                .to raise_error(Exceptions::UnprocessableEntity)
                .and not_change(current_agents, :count)
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
                .to raise_error(Exceptions::UnprocessableEntity)
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
                .to raise_error(Exceptions::UnprocessableEntity)
                .and not_change(current_agents, :count)
            end
          end
        end
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

        it 'adds CallerId record on creation (via Cti::CallerId.build)' do
          expect(Cti::CallerId).to receive(:build).with(user)

          user.save
        end

        it 'does not update CallerId record on touch/update (via Cti::CallerId.build)' do
          expect(Cti::CallerId).to receive(:build).with(user)
          user.save

          expect(Cti::CallerId).not_to receive(:build).with(user)
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
              end.not_to change { logs.map(&:reload).map(&:attributes) }
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
        expect { create(:agent, organization: nil, organizations: [create(:organization)]) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Secondary organizations are only allowed when the primary organization is given.')
      end

      it 'does not allow creation with more than 250 organizations' do
        expect { create(:agent, organization: create(:organization), organizations: create_list(:organization, 251)) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: More than 250 secondary organizations are not allowed.')
      end
    end
  end
end
