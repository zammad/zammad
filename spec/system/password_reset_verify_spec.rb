# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Password Reset verify', authenticated_as: false, type: :system do
  context 'with a valid token' do
    let(:user)  { create(:agent) }
    let(:token) { User.password_reset_new_token(user.email)[:token].name }

    before do
      visit "password_reset_verify/#{token}"
    end

    it 'resetting password with non matching passwords fail' do
      fill_in 'password', with: 'some'
      fill_in 'password_confirm', with: 'some2'

      click '.js-passwordForm .js-submit'

      expect(page).to have_text 'passwords do not match'
    end

    it 'resetting password with weak password fail' do
      fill_in 'password', with: 'some'
      fill_in 'password_confirm', with: 'some'

      click '.js-passwordForm .js-submit'

      expect(page).to have_text 'Invalid password'
    end

    it 'successfully resets password and logs in' do
      new_password = generate(:password_valid)

      fill_in 'password', with: new_password
      fill_in 'password_confirm', with: new_password

      click '.js-passwordForm .js-submit'

      expect(page).to have_text('Your password has been changed')
        .and have_selector(".user-menu .user a[title=#{user.login}")
    end
  end

  context 'without a valid token' do
    it 'error shown if opened with a not existing token' do
      visit 'password_reset_verify/not_existing_token'

      expect(page).to have_text 'Token is invalid'
    end
  end
end
