# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Password Reset', type: :system do
  before do
    visit 'password_reset'
  end

  it 'logged in user cannot open password reset' do
    expect(page).to have_no_text 'password'
  end

  context 'when not logged in', authenticated_as: false do
    it 'proceeds with non-existant user' do
      fill_in 'username', with: 'nonexisting'

      click '.reset_password .btn--primary'

      expect(page).to have_text 'sent password reset instructions'
    end

    it 'proceeds with an actual user' do
      user = create(:agent)

      fill_in 'username', with: user.email

      click '.reset_password .btn--primary'

      expect(page).to have_text 'sent password reset instructions'
    end
  end
end
