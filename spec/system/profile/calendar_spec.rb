# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Calendar', type: :system do
  before do
    visit 'profile/calendar_subscriptions'
  end

  context 'when api enabled', authenticated_as: :authenticate do
    def authenticate
      Setting.set('api_password_access', true)
      true
    end

    it 'does not show any warning about the API access' do
      expect(page).to have_no_text('REST API access using the username/email address and password is currently disabled. Please contact your administrator.')
    end
  end

  context 'when api disabled', authenticated_as: :authenticate do
    def authenticate
      Setting.set('api_password_access', false)
      true
    end

    it 'does show warning about the API access' do
      expect(page).to have_text('REST API access using the username/email address and password is currently disabled. Please contact your administrator.')
    end
  end
end
