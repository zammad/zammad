# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::TwoFactorPreference, type: :model do
  describe 'hooks' do
    context 'when after_destroy/after_save is triggered' do
      let(:user)                         { create(:user) }
      let(:authenticator_app_preference) { create(:user_two_factor_preference, :authenticator_app, user: user) }
      let(:security_keys_preference)     { create(:user_two_factor_preference, :security_keys, user: user) }

      before do
        Setting.set('two_factor_authentication_method_security_keys', true)
        Setting.set('two_factor_authentication_method_authenticator_app', true)
      end

      context 'when user has no two-factor preferences' do
        before do
          authenticator_app_preference
        end

        it 'removes the default method from user preferences' do
          expect { user.reload.two_factor_preferences.destroy_all }
            .to change { user.reload.two_factor_default }
            .from('authenticator_app')
            .to(nil)
        end
      end

      context 'when user has two-factor preferences' do
        before do
          security_keys_preference
          authenticator_app_preference
        end

        context 'when default method is removed' do
          it 'updates the default method in user preferences' do
            expect { security_keys_preference.destroy! }
              .to change { user.reload.two_factor_default }
              .from('security_keys')
              .to('authenticator_app')
          end
        end
      end
    end
  end
end
