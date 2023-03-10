# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App links', app: :mobile, type: :system do

  context 'with "Continue to desktop" link' do

    shared_examples 'redirecting to desktop app' do |source, target|
      it 'redirects to desktop app and remembers the choice' do
        visit source, skip_waiting: source == 'login'

        click 'a', text: 'Continue to desktop'

        expect_current_route(target, app: :desktop)

        visit source, skip_waiting: true

        expect_current_route(target, app: :desktop)
      end
    end

    context 'when user is unauthenticated', authenticated_as: false do
      it_behaves_like 'redirecting to desktop app', 'login', 'login'
    end

    context 'when user is authenticated' do
      it_behaves_like 'redirecting to desktop app', 'account', 'dashboard'
    end
  end

  context 'with "Continue to mobile" link' do

    shared_examples 'hiding the mobile app link' do |source, authenticated: false|
      it 'hides the mobile app link' do
        visit source, app: :desktop

        if authenticated
          find('a[href="#current_user"]').click
        end

        expect(page).to have_no_css('a', text: 'Continue to mobile')
      end
    end

    shared_examples 'redirecting to mobile app' do |source, target, authenticated: false|
      it 'redirects to mobile app and does not remember the choice' do
        visit source, app: :desktop

        if authenticated
          find('a[href="#current_user"]').click
        end

        click 'a', text: 'Continue to mobile'

        expect_current_route(target, app: :mobile)

        visit source, app: :desktop

        expect_current_route(source, app: :desktop)
      end
    end

    context 'with desktop user agent' do
      context 'when user is unauthenticated', authenticated_as: false do
        it_behaves_like 'hiding the mobile app link', 'login'
      end

      context 'when user is authenticated' do
        it_behaves_like 'hiding the mobile app link', 'dashboard', authenticated: true
      end
    end

    context 'with mobile user agent', mobile_user_agent: true do
      context 'when user is unauthenticated', authenticated_as: false do
        it_behaves_like 'redirecting to mobile app', 'login', 'login'
      end

      context 'when user is authenticated' do
        it_behaves_like 'redirecting to mobile app', 'dashboard', '', authenticated: true
      end
    end
  end
end
