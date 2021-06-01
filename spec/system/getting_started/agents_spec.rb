# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Getting Started > Agents', type: :system do
  it 'shows password strength error' do
    visit 'getting_started/agents'

    fill_in 'firstname',        with: 'Test'
    fill_in 'lastname',         with: 'Test'
    fill_in 'email',            with: 'master@example.com'

    click '.btn--success'

    within '.js-danger' do
      expect(page)
        .to have_text("Email address 'master@example.com' is already used for other user.")
    end
  end
end
