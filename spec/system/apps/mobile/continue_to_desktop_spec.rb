# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Continue to desktop', app: :mobile, type: :system do
  shared_examples 'redirecting to desktop app' do |source, target|
    it 'redirects to desktop app and remembers the choice' do
      visit source, skip_waiting: source == 'login'

      click 'a', text: 'Continue to desktop'

      expect_current_route(target, app:)

      visit source, skip_waiting: true

      expect_current_route(target, app:)
    end
  end

  context 'when user is unauthenticated', authenticated_as: false do
    it_behaves_like 'redirecting to desktop app', 'login', 'login'
  end

  context 'when user is authenticated' do
    it_behaves_like 'redirecting to desktop app', 'account', 'dashboard'
  end
end
