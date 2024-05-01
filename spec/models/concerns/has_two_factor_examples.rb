# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'User::HasTwoFactor' do
  subject(:user) { create(:user) }

  describe 'Instance methods:' do
    describe '#two_factor_configured?' do
      before do
        Setting.set('two_factor_authentication_method_authenticator_app', true)
      end

      context 'with no two factor configured' do
        it { is_expected.not_to be_two_factor_configured }
      end

      context 'with two factor configured' do
        before do
          Setting.set('two_factor_authentication_method_authenticator_app', true)
          create(:user_two_factor_preference, :authenticator_app, user: user)
          user.reload
        end

        it { is_expected.to be_two_factor_configured }
      end
    end
  end
end
