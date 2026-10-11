# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > PreferencesPermissionCheck', type: :system do
  let(:admin)    { create(:admin) }
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer) }

  before { visit 'profile' }

  shared_examples 'showing the profile page links' do |shown:, hidden: []|
    it "shows #{shown.join(', ')}#{" but not #{hidden.join(', ')}" if hidden.present?}" do
      within '.content .NavBarProfile' do
        shown.each { |link_name| expect(page).to have_link(link_name) }
        hidden.each { |link_name| expect(page).to have_no_link(link_name) }
      end
    end
  end

  context 'when logged in as admin', authenticated_as: :admin do
    it_behaves_like 'showing the profile page links', shown: ['Password', 'Language', 'Linked Accounts', 'Avatar', 'Notifications', 'Out of Office', 'Calendar', 'Devices', 'Token Access']
  end

  context 'when logged in as agent', authenticated_as: :agent do
    it_behaves_like 'showing the profile page links', shown: ['Password', 'Language', 'Linked Accounts', 'Avatar', 'Notifications', 'Out of Office', 'Calendar', 'Devices', 'Token Access']
  end

  context 'when a custom role grants user_preferences.device', authenticated_as: :user do
    let(:device_role) { create(:role, permission_names: %w[user_preferences.device]) }
    let(:user)        { create(:customer).tap { |customer| customer.roles << device_role } }

    it_behaves_like 'showing the profile page links', shown: %w[Password Language Devices], hidden: ['Notifications', 'Calendar', 'Token Access']

    context 'when the custom role is deactivated' do
      let(:user) { super().tap { device_role.update!(active: false) } }

      it_behaves_like 'showing the profile page links', shown: %w[Password], hidden: %w[Devices]
    end
  end

  context 'when logged in as customer', authenticated_as: :customer do
    it_behaves_like 'showing the profile page links', shown: ['Password', 'Language', 'Linked Accounts', 'Avatar'], hidden: ['Notifications', 'Calendar', 'Token Access']
  end
end
