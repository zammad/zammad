# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Getting Started > Admin', authenticated_as: false, set_up: false, type: :system do
  it 'shows password strength error' do
    visit 'getting_started/admin'

    fill_in 'firstname',        with: 'Test'
    fill_in 'lastname',         with: 'Test'
    fill_in 'email',            with: 'test@example.com'
    fill_in 'password',         with: 'asdasdasdasd'
    fill_in 'password_confirm', with: 'asdasdasdasd'

    click '.btn--success'

    within '.js-danger' do
      expect(page).to have_text('Invalid password,').and(have_no_text('["'))
    end
  end
end
