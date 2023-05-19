# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/authenticator_app_setup_examples'

RSpec.describe 'Profile > Password', authenticated_as: :user, type: :system do
  let(:user) { create(:agent, :with_valid_password) }

  describe 'visibility' do
    it 'not available if both two factor and password changing disabled' do
      password_and_authenticate(password: false, two_factor: false)

      visit 'profile/'
      expect(page).to have_no_text('Password & Authentication')
    end

    it 'shows only password changing form if two factor disabled' do
      password_and_authenticate(password: true, two_factor: false)

      visit 'profile/password'

      expect(page)
        .to have_text('Change Your Password')
        .and have_no_text('Two-factor Authentication')
    end

    it 'shows only two factor if password changing disabled' do
      password_and_authenticate(password: false, two_factor: true)

      visit 'profile/password'

      expect(page)
        .to have_no_text('Change Your Password')
        .and have_text('Two-factor Authentication')
    end

    def password_and_authenticate(password:, two_factor:)
      Setting.set('two_factor_authentication_method_authenticator_app', two_factor)
      Setting.set('two_factor_authentication_enforce_role_ids', [])
      Setting.set('user_show_password_login', password)
    end
  end

  context 'when changing password' do
    before do
      visit 'profile/password'
    end

    it 'when current password is wrong, show error' do
      fill_in 'password_old',         with: 'nonexisting'
      fill_in 'password_new',         with: 'some'
      fill_in 'password_new_confirm', with: 'some'

      click '.btn--primary'

      expect(page).to have_text 'Current password is wrong'
    end

    it 'when new passwords do not match, show error' do
      fill_in 'password_old',         with: user.password_plain
      fill_in 'password_new',         with: 'some'
      fill_in 'password_new_confirm', with: 'some2'

      click '.btn--primary'

      expect(page).to have_text 'passwords do not match'
    end

    it 'when new password is invalid, show error' do
      fill_in 'password_old',         with: user.password_plain
      fill_in 'password_new',         with: 'some'
      fill_in 'password_new_confirm', with: 'some'

      click '.btn--primary'

      expect(page).to have_text 'Invalid password'
    end

    it 'allows to change password' do
      new_password = generate(:password_valid)

      fill_in 'password_old',         with: user.password_plain
      fill_in 'password_new',         with: new_password
      fill_in 'password_new_confirm', with: new_password

      click '.btn--primary'

      expect(page).to have_text 'Password changed successfully!'
    end
  end

  context 'when managing two factor authentication' do
    before do
      Setting.set('two_factor_authentication_method_authenticator_app', true)
      Setting.set('two_factor_authentication_enforce_role_ids', [])
    end

    context 'without a configured method' do
      before do
        visit 'profile/password'
      end

      it 'shows available method' do
        expect(page).to have_text('Authenticator App')
      end

      it 'allows to setup two factor authentication' do
        within('tr[data-two-factor-key="authenticator_app"]') do
          expect(page).to have_css('.icon.icon-small-dot')

          click '.js-action'

          find('a', text: 'Set Up').click
        end

        setup_authenticator_app_method(user: user, password_check: user.password_plain)

        within('tr[data-two-factor-key="authenticator_app"]') do
          expect(page).to have_css('.icon.icon-checkmark')
          expect(page).to have_text('Default')
        end
      end
    end

    context 'with a configured method' do
      before do
        create(:user_two_factor_preference, user: user)
        visit 'profile/password'
      end

      it 'shows configured method as ready' do
        within('tr[data-two-factor-key="authenticator_app"]') do
          expect(page).to have_css('.icon.icon-checkmark')
          expect(page).to have_text('Default')
        end
      end

      it 'allows to remove an existing two factor authentication' do
        within('tr[data-two-factor-key="authenticator_app"]') do
          click '.js-action'

          find('a', text: 'Remove').click
        end

        in_modal do
          click_on 'Yes'
        end

        within('tr[data-two-factor-key="authenticator_app"]') do
          expect(page).to have_css('.icon.icon-small-dot')
        end
      end
    end
  end
end
