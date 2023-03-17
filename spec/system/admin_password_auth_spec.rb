# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Admin password auth', type: :system do
  before do
    Setting.set('user_show_password_login', false)
    Setting.set('auth_saml', true)
  end

  context 'when logged in already' do
    before do
      visit 'admin_password_auth'
    end

    it 'logged in user cannot open admin password auth' do
      expect(page).to have_no_text 'password'
    end
  end

  context 'when not logged in', authenticated_as: false do
    def request_admin_password_auth
      visit 'admin_password_auth'
      fill_in 'username', with: username
      click '.btn--primary'
    end

    before do
      freeze_time
      request_admin_password_auth
    end

    context 'with non-existant user' do
      let(:username) { 'nonexisting' }

      it 'pretends to proceed' do
        expect(page).to have_text 'sent admin password login instructions'
      end
    end

    context 'with existing admin' do
      let(:user)             { create(:admin) }
      let(:username)         { user.email }
      let(:generated_tokens) { Token.where(action: 'AdminAuth', user_id: user.id) }

      it 'login is possible' do
        expect(page).to have_text 'sent admin password login instructions'
        expect(generated_tokens.count).to eq 1
        expect(generated_tokens.first.persistent).to be false

        visit "/#login/admin/#{generated_tokens[0].name}"

        expect(page).to have_selector '#username'
      end
    end
  end

  context 'with invalid token', authenticated_as: false do
    it 'login is not possible' do
      visit '/#login/admin/invalid-token'

      expect(page).to have_text 'The token for the admin password login is invalid.'
    end
  end
end
