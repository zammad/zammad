# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > PreferencesPermissionCheck', type: :system do
  let(:admin)    { create(:admin) }
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer) }

  before { visit 'profile' }

  shared_examples 'having profile page link to' do |link_name|
    it "shows the #{link_name} link" do
      within '.content .NavBarProfile' do
        expect(page).to have_link(link_name)
      end
    end
  end

  shared_examples 'not having profile page link to' do |link_name|
    it "does not show the #{link_name} link" do
      within '.content .NavBarProfile' do
        expect(page).to have_no_link(link_name)
      end
    end
  end

  context 'when logged in as admin', authenticated_as: :admin do
    it_behaves_like 'having profile page link to', 'Password'

    it_behaves_like 'having profile page link to', 'Language'

    it_behaves_like 'having profile page link to', 'Linked Accounts'

    it_behaves_like 'having profile page link to', 'Avatar'

    it_behaves_like 'having profile page link to', 'Notifications'

    it_behaves_like 'having profile page link to', 'Out of Office'

    it_behaves_like 'having profile page link to', 'Calendar'

    it_behaves_like 'having profile page link to', 'Devices'

    it_behaves_like 'having profile page link to', 'Token Access'
  end

  context 'when logged in as agent', authenticated_as: :agent do
    it_behaves_like 'having profile page link to', 'Password'

    it_behaves_like 'having profile page link to', 'Language'

    it_behaves_like 'having profile page link to', 'Linked Accounts'

    it_behaves_like 'having profile page link to', 'Avatar'

    it_behaves_like 'having profile page link to', 'Notifications'

    it_behaves_like 'having profile page link to', 'Out of Office'

    it_behaves_like 'having profile page link to', 'Calendar'

    it_behaves_like 'having profile page link to', 'Devices'

    it_behaves_like 'having profile page link to', 'Token Access'
  end

  context 'when a custom role grants user_preferences.device', authenticated_as: :user do
    let(:device_role) { create(:role, permission_names: %w[user_preferences.device]) }
    let(:user)        { create(:customer).tap { |customer| customer.roles << device_role } }

    it_behaves_like 'having profile page link to', 'Password'

    it_behaves_like 'having profile page link to', 'Language'

    it_behaves_like 'not having profile page link to', 'Notifications'

    it_behaves_like 'not having profile page link to', 'Calendar'

    it_behaves_like 'not having profile page link to', 'Token Access'

    it_behaves_like 'having profile page link to', 'Devices'

    context 'when the custom role is deactivated' do
      let(:user) { super().tap { device_role.update!(active: false) } }

      it_behaves_like 'having profile page link to', 'Password'

      it_behaves_like 'not having profile page link to', 'Devices'
    end
  end

  context 'when logged in as customer', authenticated_as: :customer do
    it_behaves_like 'having profile page link to', 'Password'

    it_behaves_like 'having profile page link to', 'Language'

    it_behaves_like 'having profile page link to', 'Linked Accounts'

    it_behaves_like 'having profile page link to', 'Avatar'

    it_behaves_like 'not having profile page link to', 'Notifications'

    it_behaves_like 'not having profile page link to', 'Calendar'

    it_behaves_like 'not having profile page link to', 'Token Access'
  end
end
