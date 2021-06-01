# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Authentication', type: :system do

  it 'Login', authenticated_as: false do
    login(
      username: 'master@example.com',
      password: 'test',
    )

    expect_current_route 'dashboard'
  end

  it 'Logout' do
    logout
    expect_current_route 'login', wait: 2
  end

  it 'will unset user attributes after logout' do
    logout
    expect_current_route 'login', wait: 2

    visit '/#signup'

    # check wrong displayed fields in registration form after logout. #2989
    expect(page).to have_no_selector('select[name=organization_id]')
  end

  it 'Login and redirect to requested url', authenticated_as: false do
    visit 'ticket/zoom/1'

    expect_current_route 'login', wait: 2

    login(
      username: 'master@example.com',
      password: 'test',
    )

    expect_current_route 'ticket/zoom/1', wait: 2
  end

  it 'Login and redirect to requested url via external authentication', authenticated_as: false do
    visit 'ticket/zoom/1'

    expect_current_route 'login', wait: 2

    # simulate jump to external ressource
    visit 'https://www.zammad.org'

    # simulate successful login via third party
    user = User.find_by(login: 'master@example.com')
    ActiveRecord::SessionStore::Session.all.each do |session|
      session.data[:user_id] = user.id
      session.save!
    end

    # jump back and check if origin requested url is shown
    visit ''

    expect_current_route 'ticket/zoom/1', wait: 2

    expect(current_login).to eq('master@example.com')
  end

end
