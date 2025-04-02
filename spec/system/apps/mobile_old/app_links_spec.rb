# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App links', app: :mobile, type: :system do

  def disable_auto_redirect
    # Force desktop view in order to circumvent the automatic redirection to mobile.
    page.evaluate_script "window.localStorage.setItem('forceDesktopApp', true)"
  end

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

    shared_examples 'redirecting to mobile app' do |source, target|
      it 'redirects to mobile app' do
        visit source, app: :desktop

        find('a[href="#current_user"]').click

        click 'a', text: 'Continue to mobile'

        expect(page).to have_no_text('Loading failed')
        expect_current_route(target, app: :mobile)
      end
    end

    context 'with desktop user agent' do
      context 'when user is unauthenticated', authenticated_as: false do
        it_behaves_like 'hiding the mobile app link', 'login'
      end

      context 'when user is authenticated' do
        it_behaves_like 'hiding the mobile app link', 'dashboard'
      end
    end

    context 'with mobile user agent', mobile_user_agent: true do

      context 'when user is unauthenticated', authenticated_as: false do
        it 'redirects to mobile' do
          visit '/'
          disable_auto_redirect

          click_on('Continue to desktop')

          expect_current_route('login', app: :desktop)

          click_on('Continue to mobile')

          expect(page).to have_no_text('Loading failed')
          expect_current_route('login', app: :mobile)
        end
      end

      context 'when user is authenticated' do
        before do
          visit '/'
          disable_auto_redirect
        end

        it_behaves_like 'redirecting to mobile app', 'profile', 'profile'
        it_behaves_like 'redirecting to mobile app', 'profile/avatar', 'profile/avatar'
        it_behaves_like 'redirecting to mobile app', 'organization/profile/1', 'organization/profile/1'
        it_behaves_like 'redirecting to mobile app', 'search/string', 'search/ticket?search=string'
        it_behaves_like 'redirecting to mobile app', 'ticket/create', 'ticket/create'
        it_behaves_like 'redirecting to mobile app', 'ticket/zoom/1', 'ticket/zoom/1'
        it_behaves_like 'redirecting to mobile app', 'user/profile/1', 'user/profile/1'
        it_behaves_like 'redirecting to mobile app', 'dashboard', %r{mobile/$}

        context 'with customer user', authenticated_as: :customer do
          let(:customer) { create(:customer) }

          it_behaves_like 'redirecting to mobile app', 'ticket/view/my_tickets', 'ticket/view/my_tickets'
        end
      end
    end
  end

  context 'with mobile device detection', mobile_user_agent: true do
    shared_examples 'automatically redirecting to mobile app' do |source, target|
      it 'automatically redirects to mobile app' do
        visit source, app: :desktop

        expect_current_route(target, app: :mobile)
      end
    end

    it_behaves_like 'automatically redirecting to mobile app', '/', %r{mobile/$}
    it_behaves_like 'automatically redirecting to mobile app', 'ticket/zoom/1', 'ticket/zoom/1'

    context 'when not authenticated', authenticated_as: false do
      it 'forgot password doesn\'t redirect back' do
        visit '/login', app: :mobile

        click_on 'Forgot password?'

        expect_current_route('password_reset', app: :desktop)

        expect(page).to have_no_link('Continue to desktop')
      end

      it "register doesn't redirect back" do
        visit '/login', app: :mobile

        click_on 'Register'

        expect_current_route('signup', app: :desktop)

        expect(page).to have_no_link('Continue to desktop')
      end
    end
  end
end
