# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_attachment_test.rb (the customer/organization
#   sync scenarios of test_ticket): changes to the ticket customer and its profile
#   made in one session become visible in a second open session without a reload.
RSpec.describe 'Scenario > Ticket customer changes sync into open sessions', authenticated_as: :authenticate, sessions_jobs: true, type: :system do
  let(:group)        { Group.find_by(name: 'Users') }
  let(:agent)        { create(:agent, password: 'test', groups: [group]) }
  let(:second_agent) { create(:agent, password: 'test', groups: [group]) }
  let(:customer)     { create(:customer, firstname: 'Nicole', lastname: 'Braun') }
  let(:new_customer) { create(:customer, firstname: 'Sync', lastname: 'Target', organization: create(:organization, name: 'Sync Organization')) }
  let(:ticket)       { create(:ticket, group:, customer:) }

  def authenticate
    new_customer
    ticket

    agent
  end

  it 'shows customer changes of one session live in the other' do
    visit "#ticket/zoom/#{ticket.id}"

    within(:active_content) do
      click '.tabsSidebar-tab[data-tab="customer"]'
    end

    # A second session (of another agent, to avoid the session takeover
    #   dialog) changes the ticket customer...
    using_session(:second_browser) do
      login(username: second_agent.login, password: 'test')

      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        find('[data-tab="ticket"] .js-actions').click
        click '[data-type="customer-change"]'
      end

      in_modal do
        find('[name="customer_id_completion"]').fill_in with: new_customer.email

        expect(page).to have_css('.recipientList-entry.js-object')
        first('.recipientList-entry.js-object').click

        click_on 'Submit'
      end
    end

    # ...and the first session sees the new customer and organization without reload.
    within '.content.active .sidebar[data-tab="customer"]' do
      expect(page).to have_text(new_customer.email)
    end

    expect(page).to have_css('.content.active .tabsSidebar-tab[data-tab="organization"]')

    # Editing the customer in the first session syncs into the second session.
    within(:active_content) do
      click '#userAction'
      click '.sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]'
    end

    in_modal do
      fill_in 'address', with: 'some new address'

      click_on 'Submit'
    end

    using_session(:second_browser) do
      within(:active_content) do
        click '.tabsSidebar-tab[data-tab="customer"]'
      end

      within '.content.active .sidebar[data-tab="customer"]' do
        expect(page).to have_text('some new address')
      end
    end
  end
end
