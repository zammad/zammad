# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Authentication', type: :system do
  it 'Login', authenticated_as: false do
    login(
      username: 'admin@example.com',
      password: 'test',
    )

    expect_current_route 'dashboard'

    refresh

    # Check that cookies is temporary.
    cookie = cookie('^_zammad.+?')
    expect(cookie[:expires]).to be_nil
  end

  it 'Login with remember me', authenticated_as: false do
    login(
      username:    'admin@example.com',
      password:    'test',
      remember_me: true
    )

    expect_current_route 'dashboard'

    refresh

    # Check that cookies has a  expire date.
    cookie = cookie('^_zammad.+?')
    expect(cookie[:expires]).to be_truthy

    logout
    expect_current_route 'login'

    # Check that cookies has no longer a expire date after logout.
    cookie = cookie('^_zammad.+?')
    expect(cookie[:expires]).to be_nil
  end

  it 'Logout' do
    logout
    expect_current_route 'login'
  end

  it 'will unset user attributes after logout' do
    logout
    expect_current_route 'login'

    visit '/#signup'

    # check wrong displayed fields in registration form after logout. #2989
    expect(page).to have_no_select('organization_id')
  end

  it 'Login and redirect to requested url', authenticated_as: false do
    visit 'ticket/zoom/1'

    expect_current_route 'login'

    login(
      username: 'admin@example.com',
      password: 'test',
    )

    expect_current_route 'ticket/zoom/1'
  end

  it 'Login and redirect to requested url via external authentication', authenticated_as: false do
    visit 'ticket/zoom/1'

    expect_current_route 'login'

    # simulate jump to external ressource
    visit 'https://www.zammad.org'

    # simulate successful login via third party
    user = User.find_by(login: 'admin@example.com')
    ActiveRecord::SessionStore::Session.all.each do |session|
      session.data[:user_id] = user.id
      session.save!
    end

    # jump back and check if origin requested url is shown
    visit ''

    expect_current_route 'ticket/zoom/1'

    expect(current_login).to eq('admin@example.com')
  end

end
