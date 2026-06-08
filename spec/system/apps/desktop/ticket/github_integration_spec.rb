# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > GitHub Integration', app: :desktop_view, authenticated_as: :agent, required_envs: %w[GITHUB_ENDPOINT GITHUB_APITOKEN GITHUB_ISSUE_LINK], type: :system do
  let(:agent)         { create(:agent, groups: [group]) }
  let(:group)         { create(:group) }
  let(:customer)      { create(:customer) }

  before do
    Setting.set('github_integration', true)
    Setting.set('github_config', {
                  api_token: ENV['GITHUB_APITOKEN'],
                  endpoint:  ENV['GITHUB_ENDPOINT'],
                })
  end

  context 'when creating a ticket' do
    before do
      visit '/ticket/create'
      wait_for_form_to_settle('ticket-create')
    end

    it 'creates a new ticket' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type('Example Ticket Title')
        find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
        find_editor('Text').type('GitHub Integration Test')
      end

      click_on 'GitHub'
      click_on 'Link issue'

      within '#flyout-link-github-issue' do
        find_input('Issue URL').type(ENV['GITHUB_ISSUE_LINK'])
        click_on 'Link issue'
      end

      within '#ticketSidebar' do
        expect(page).to have_text('#1575 GitHub integration')
      end

      click_on 'Create'

      expect(page).to have_text('Ticket has been created successfully')

      click_on 'GitHub'
      within '#ticketSidebar' do
        expect(page).to have_text('#1575 GitHub integration')
        expect(page).to have_text('4.0')
        expect(page).to have_text('Thorsten')
        expect(page).to have_text('enhancement')
        expect(page).to have_text('integration')
      end
    end

  end
end
