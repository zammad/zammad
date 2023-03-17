# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration', type: :system do
  before do
    visit '#system/integration'
  end

  describe 'Switching on/off integrations (e.g. LDAP + Exchange) leads to unpredictable results #4181' do
    it 'does not switch on multiple integrations' do
      click_link 'GitHub'
      click_link 'Integrations'
      click_link 'GitLab'
      click '.js-switch'
      click_link 'Integrations'
      expect(page).to have_css('tr[data-key=IntegrationGitLab] .icon-status.ok')
      expect(page).to have_no_css('tr[data-key=IntegrationGitHub] .icon-status.ok')
    end
  end
end
