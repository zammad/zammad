require 'rails_helper'

RSpec.describe 'Disable login form', type: :system, authenticated_as: false do
  context 'with enable default login form' do
    before { Setting.set 'user_show_default_login', true }

    it 'shows login form' do
      visit '/'
        expect(page).to have_selector('#login')
    end
  end

  context 'with disable default login form' do
    before { Setting.set 'user_show_default_login', false }

    it 'show login form when no third application enable' do
      Setting.set 'auth_saml', false
      visit '/'
      expect(page).to have_selector('#login')
    end

    it 'show hide form when third application' do
      Setting.set 'auth_saml', true
      visit '/'
      expect(page).to have_no_selector('#login')
    end
  end
end
