# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Password Reset', type: :system do
  context 'when logged in already' do
    before do
      visit 'password_reset'
    end

    it 'logged in user cannot open password reset' do
      expect(page).to have_no_text 'password'
    end
  end

  context 'when not logged in', authenticated_as: false do
    def request_reset
      visit 'password_reset'
      fill_in 'username', with: username
      click '.reset_password .btn--primary'
    end

    before do
      freeze_time
      request_reset
    end

    context 'with non-existant user' do
      let(:username) { 'nonexisting' }

      it 'pretends to proceed' do
        expect(page).to have_text 'sent password reset instructions'
      end
    end

    context 'with existing user' do
      let(:user) { create(:agent) }
      let(:username)         { user.email }
      let(:generated_tokens) { Token.where(action: 'PasswordReset', user_id: user.id) }

      it 'proceeds' do
        expect(page).to have_text 'sent password reset instructions'
      end

      it 'creates a token' do
        expect(generated_tokens.count).to eq 1
      end

      it 'token will expire' do
        expect(generated_tokens.first.persistent).to be false
      end

      context 'when submitting multiple times' do
        before do
          refresh
          request_reset # a second time now
        end

        it 'proceeds' do
          expect(page).to have_text 'sent password reset instructions'
        end

        it 'discards the previous token' do
          expect(generated_tokens.count).to eq 1
        end
      end
    end
  end
end
