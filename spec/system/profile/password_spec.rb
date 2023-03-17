# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Password', authenticated_as: :user, type: :system do
  before do
    visit 'profile/password'
  end

  let(:user) { create(:agent, :with_valid_password) }

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
