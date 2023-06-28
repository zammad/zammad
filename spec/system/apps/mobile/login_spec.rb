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

  it 'Login and redirect to requested url' do
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
    let(:user)                 { User.find_by(login: 'admin@example.com') }
    let(:code)                 { two_factor_pref.configuration[:code] }
    let(:recover_code_enabled) { false }
    let!(:two_factor_pref)     { create(:user_two_factor_preference, :authenticator_app, user:) }
    let(:token)                { 'token' }
    let(:recovery_2fa)         { create(:user_two_factor_preference, :recovery_codes, recovery_code: token, user:) }

    before do
      stub_const('Auth::BRUTE_FORCE_SLEEP', 0)
      recovery_2fa if recover_code_enabled
      Setting.set('two_factor_authentication_recovery_codes', recover_code_enabled)

      visit '/login', skip_waiting: true

      login(
        username:     'admin@example.com',
        password:     'test',
        remember_me:  true,
        skip_waiting: true,
      )
    end

    it 'can login with correct code' do
      expect(page).to have_no_text('Try another method')

      find_input('Security Code').type(code)
      find_button('Sign in').click

      expect_current_route '/'
    end

    context 'when logging in with recovery code' do
      let(:recover_code_enabled) { true }

      before do
        find_button('Try another method').click
        find_button('Or use one of your recovery codes.').click
      end

      it 'can login with correct code' do
        find_input('Recovery Code').type(token)
        find_button('Sign in').click

        expect_current_route '/'
      end

      it 'shows an error with incorrect code' do
        find_input('Recovery Code').type('incorrect')
        find_button('Sign in').click

        expect(page).to have_text('Please double-check your two-factor authentication method')

        expect_current_route '/login'
      end
    end
  end

end
