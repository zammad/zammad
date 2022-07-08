# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Login', type: :system, app: :mobile, authenticated_as: false do
  it 'Login with remember me and logout again' do
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

  it 'Login and redirect to requsted url' do
    visit 'notifications'

    expect_current_route '/login?redirect=/notifications'

    login(
      username: 'admin@example.com',
      password: 'test',
    )

    expect_current_route '/notifications'
  end
end
