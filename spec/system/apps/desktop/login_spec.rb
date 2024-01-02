# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Login', app: :desktop_view, authenticated_as: false, type: :system do
  it 'Login with remember me and logout again' do
    visit '/login', skip_waiting: true

    login(
      username:    'admin@example.com',
      password:    'test',
      remember_me: true,
    )

    expect_current_route '/'

    refresh

    cookie = cookie('^_zammad.+?')
    expect(cookie[:expires]).to be_truthy

    logout
    expect_current_route 'login'

    # Check that cookies has no longer a expire date after logout.
    cookie = cookie('^_zammad.+?')
    expect(cookie[:expires]).to be_nil
  end

  it 'Login and redirect to requested url' do
    visit '/playground', skip_waiting: true

    expect_current_route '/login?redirect=/playground' # TODO: FIX route to valid desktop view route instead of playground

    login(
      username: 'admin@example.com',
      password: 'test',
    )

    expect_current_route '/playground'
  end
end
