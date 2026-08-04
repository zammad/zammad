# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/user_access_permissions_test.rb as a continuous end-to-end
#   scenario: an agent may edit customer users (user profile and ticket customer
#   sidebar, including the saved values showing up again), but must not be offered
#   any edit action for admin users.
RSpec.describe 'Scenario > User access permissions of an agent', authenticated_as: :agent, type: :system do
  let(:group)           { Group.find_by(name: 'Users') }
  let(:agent)           { create(:agent, groups: [group]) }
  let(:customer_user)   { create(:customer, firstname: 'Nicole', lastname: 'Braun') }
  let(:admin_user)      { create(:admin, firstname: 'Test', lastname: 'Admin') }
  let(:customer_ticket) { create(:ticket, group:, customer: customer_user) }
  let(:admin_ticket)    { create(:ticket, group:, customer: admin_user) }

  it 'allows editing customer users but never admin users' do
    # User profile of a customer: edit action is offered, saved values show up again.
    visit "#user/profile/#{customer_user.id}"

    within(:active_content) do
      expect(page).to have_css('.profile-window', text: customer_user.email)

      click '.js-action .icon-arrow-down'
      click '.js-action [data-type="edit"]'
    end

    in_modal do
      fill_in 'lastname', with: 'B2'
      find('[data-name="note"]').send_keys 'some note abc'

      click_on 'Submit'
    end

    within(:active_content) do
      expect(page).to have_css('.profile-window', text: 'some note abc')
    end

    expect(page).to have_css('.tasks-navigation', text: 'Nicole B2')

    # User profile of an admin: no edit action is offered.
    visit "#user/profile/#{admin_user.id}"

    within(:active_content) do
      expect(page).to have_css('.profile-window', text: admin_user.email)

      click '.js-action .icon-arrow-down'

      expect(page).to have_no_css('.js-action [data-type="edit"]')
    end

    # Ticket of a customer: the customer sidebar offers the edit action,
    #   saved values show up in the sidebar again.
    visit "#ticket/zoom/#{customer_ticket.id}"

    within(:active_content) do
      click '.tabsSidebar-tab[data-tab="customer"]'
      click '#userAction'
      click '.sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]'
    end

    in_modal do
      fill_in 'lastname', with: 'B3'

      click_on 'Submit'
    end

    within '.content.active .sidebar[data-tab="customer"]' do
      expect(page).to have_css('h3[title="Name"]', text: 'Nicole B3')
    end

    # Ticket of an admin customer: the customer sidebar offers no edit action.
    visit "#ticket/zoom/#{admin_ticket.id}"

    within(:active_content) do
      click '.tabsSidebar-tab[data-tab="customer"]'
      click '#userAction'

      expect(page).to have_no_css('.sidebar[data-tab="customer"] .js-actions [data-type="customer-edit"]')
    end
  end
end
