# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Continue to mobile', type: :system do
  shared_examples 'hiding the mobile app link' do |source, authenticated: false|
    it 'hides the mobile app link' do
      visit source

      if authenticated
        find('a[href="#current_user"]').click
      end

      expect(page).to have_no_css('a', text: 'Continue to mobile')
    end
  end

  shared_examples 'redirecting to mobile app' do |source, target, authenticated: false|
    it 'redirects to mobile app and does not remember the choice' do
      visit source

      if authenticated
        find('a[href="#current_user"]').click
      end

      expect(page).to have_css('a', text: 'Continue to mobile')

      # Avoid await_empty_ajax_queue.
      execute_script('$("a:contains(\'Continue to mobile\')")[0].click()')

      expect_current_route(target, app: :mobile)

      visit source

      expect_current_route(source, app:)
    end
  end

  context 'with desktop user agent' do
    context 'when user is unauthenticated', authenticated_as: false do
      it_behaves_like 'hiding the mobile app link', 'login'
    end

    context 'when user is authenticated' do
      it_behaves_like 'hiding the mobile app link', 'login', authenticated: true
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
