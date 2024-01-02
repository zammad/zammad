# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::TwoFactorPreference, type: :model do
  describe 'hooks' do
    context 'when after_destroy/after_save is triggered' do
      let(:user) { create(:user) }

      context 'when user has no two-factor preferences' do
        before do
          create(:user_two_factor_preference, :authenticator_app, user: user)
        end

        it 'removes the default method from user preferences' do
          user.reload.two_factor_preferences.destroy_all

          expect(user.preferences).not_to include(two_factor_authentication: { default: 'authenticator_app' })
        end
      end

      context 'when user has two-factor preferences' do
        before do
          create(:user_two_factor_preference, :authenticator_app, user: user)
          create(:user_two_factor_preference, :security_keys, user: user)
        end

        context 'when default method is removed' do
          it 'updates the default method in user preferences' do
            user.reload.two_factor_preferences.last.destroy

            expect(user.preferences.dig(:two_factor_authentication, :default)).to eq('authenticator_app')
          end
        end
      end
    end
  end
end
