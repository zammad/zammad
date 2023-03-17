# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Login', app: :mobile, authenticated_as: false, type: :system do
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

  it 'Login and redirect to requsted url' do
    visit '/notifications', skip_waiting: true

    expect_current_route '/login?redirect=/notifications'

    login(
      username: 'admin@example.com',
      password: 'test',
    )

    expect_current_route '/notifications'
  end

  it 'Shows public links' do
    link = create(:public_link)
    visit '/login', skip_waiting: true

    wait_for_gql('shared/entities/public-links/graphql/queries/links.graphql')

    expect(page).to have_link(link.title, href: link.link)

    link.update!(title: 'new link')

    wait_for_gql('shared/entities/public-links/graphql/subscriptions/currentLinks.graphql')

    expect(page).to have_link('new link', href: link.link)
  end
end
