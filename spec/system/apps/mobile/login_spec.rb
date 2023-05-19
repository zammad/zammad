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

  context 'when after auth is required' do
    it 'requires setting up two factor auth' do
      allow_any_instance_of(Auth::AfterAuth::TwoFactorConfiguration).to receive(:check).and_return(true)

      visit '/login', skip_waiting: true

      login(
        username:     'admin@example.com',
        password:     'test',
        remember_me:  true,
        skip_waiting: true,
      )

      expect(page).to have_content('The two-factor authentication is not configured yet')
      expect_current_route '/login/after-auth'
    end
  end

  context 'when logging in with two factor auth' do
    let(:code)             { two_factor_pref.configuration[:code] }
    let!(:two_factor_pref) { create(:'user/two_factor_preference', user: User.find_by(login: 'admin@example.com')) }

    before do
      stub_const('Auth::BRUTE_FORCE_SLEEP', 0)
    end

    it 'can login with correct code' do
      visit '/login', skip_waiting: true

      login(
        username:     'admin@example.com',
        password:     'test',
        remember_me:  true,
        skip_waiting: true,
      )

      find_input('Security Code').type(code)
      find_button('Sign in').click

      expect_current_route '/'
    end
  end
end
