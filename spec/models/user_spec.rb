require 'rails_helper'
require 'models/concerns/has_groups_examples'
require 'models/concerns/has_roles_examples'
require 'models/concerns/has_groups_permissions_examples'

RSpec.describe User do

  let(:group_access_instance) { create(:user, roles: [Role.find_by(name: 'Agent')]) }
  let(:new_group_access_instance) { build(:user, roles: [Role.find_by(name: 'Agent')]) }
  let(:group_access_no_permission_instance) { build(:user) }

  include_examples 'HasGroups'
  include_examples 'HasRoles'
  include_examples 'HasGroups and Permissions'

  let(:new_password) { 'N3W54V3PW!' }

  context 'password' do

    it 'resets login_failed on password change' do
      user = create(:user_login_failed)
      expect {
        user.password = new_password
        user.save
      }.to change { user.login_failed }.to(0)
    end
  end

  context '#out_of_office_agent' do

    it 'responds to out_of_office_agent' do
      user = create(:user)
      expect(user).to respond_to(:out_of_office_agent)
    end

    context 'replacement' do

      it 'finds assigned' do
        user_replacement = create(:user)

        user_ooo = create(:user,
                          out_of_office:                true,
                          out_of_office_start_at:       Time.zone.yesterday,
                          out_of_office_end_at:         Time.zone.tomorrow,
                          out_of_office_replacement_id: user_replacement.id,)

        expect(user_ooo.out_of_office_agent).to eq user_replacement
      end

      it 'finds none for available users' do
        user = create(:user)
        expect(user.out_of_office_agent).to be nil
      end
    end
  end

  context '#max_login_failed?' do

    it 'responds to max_login_failed?' do
      user = create(:user)
      expect(user).to respond_to(:max_login_failed?)
    end

    it 'checks if a user has reached the maximum of failed logins' do

      user = create(:user)
      expect(user.max_login_failed?).to be false

      user.login_failed = 999
      user.save
      expect(user.max_login_failed?).to be true
    end
  end

  context '.identify' do

    it 'returns users found by login' do
      user       = create(:user)
      found_user = User.identify(user.login)
      expect(found_user).to be_an(User)
      expect(found_user.id).to eq user.id
    end

    it 'returns users found by email' do
      user       = create(:user)
      found_user = User.identify(user.email)
      expect(found_user).to be_an(User)
      expect(found_user.id).to eq user.id
    end
  end

  context '.authenticate' do

    it 'authenticates by username and password' do
      user   = create(:user)
      result = described_class.authenticate(user.login, 'zammad')
      expect(result).to be_an(User)
    end

    context 'failure' do

      it 'increases login_failed on failed logins' do
        user = create(:user)
        expect do
          described_class.authenticate(user.login, 'wrongpw')
          user.reload
        end
          .to change { user.login_failed }.by(1)
      end

      it 'fails for unknown users' do
        result = described_class.authenticate('john.doe', 'zammad')
        expect(result).to be nil
      end

      it 'fails for inactive users' do
        user   = create(:user, active: false)
        result = described_class.authenticate(user.login, 'zammad')
        expect(result).to be nil
      end

      it 'fails for users with too many failed logins' do
        user   = create(:user, login_failed: 999)
        result = described_class.authenticate(user.login, 'zammad')
        expect(result).to be nil
      end

      it 'fails for wrong passwords' do
        user   = create(:user)
        result = described_class.authenticate(user.login, 'wrongpw')
        expect(result).to be nil
      end

      it 'fails for empty username parameter' do
        result = described_class.authenticate('', 'zammad')
        expect(result).to be nil
      end

      it 'fails for empty password parameter' do
        result = described_class.authenticate('username', '')
        expect(result).to be nil
      end
    end
  end

  context '#by_reset_token' do

    it 'returns a User instance for existing tokens' do
      token = create(:token_password_reset)
      expect(described_class.by_reset_token(token.name)).to be_instance_of(described_class)
    end

    it 'returns nil for not existing tokens' do
      expect(described_class.by_reset_token('not-existing')).to be nil
    end
  end

  context '.password_reset_via_token' do

    it 'changes the password of the token user and destroys the token' do
      token = create(:token_password_reset)
      user  = User.find(token.user_id)

      expect {
        described_class.password_reset_via_token(token.name, new_password)
        user.reload
      }.to change {
        user.password
      }.and change {
        Token.count
      }.by(-1)
    end
  end

  context 'import' do

    it "doesn't change imported passwords" do

      # mock settings calls
      expect(Setting).to receive(:get).with('import_mode').and_return(true)
      allow(Setting).to receive(:get)

      user = build(:user, password: '{sha2}dd9c764fa7ea18cd992c8600006d3dc3ac983d1ba22e9ba2d71f6207456be0ba') # zammad
      expect {
        user.save
      }.to_not change {
        user.password
      }
    end
  end
end
