# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/user_switch_cache_test.rb as a continuous end-to-end
#   scenario: after an agent session primed the client side attribute cache, a
#   customer logging in within the same browser must get the customer ticket
#   create mask (no agent-only fields), reproducibly across re-logins.
RSpec.describe 'Scenario > User switch cache', authenticated_as: :authenticate, authentication_type: :form, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:agent)    { create(:agent, password: 'test', groups: [group]) }
  let(:customer) { create(:customer, password: 'test') }

  def authenticate
    customer

    agent
  end

  def expect_customer_mask_fields
    # Customers have no taskbar, therefore no `.content.active` scope exists here.
    within '.newTicket' do
      expect(page).to have_text(%r{state}i)
      expect(page).to have_no_text(%r{priority}i)
      expect(page).to have_no_text(%r{owner}i)
    end
  end

  it 'shows the customer fields after switching from an agent session and after re-login' do
    # Prime the client side cache with the agent's ticket create form.
    visit '#ticket/create'

    within(:active_content) do
      expect(page).to have_css('.newTicket')
      expect(page).to have_text('PRIORITY')
    end

    # A customer logging in afterwards gets the customer mask, not the cached agent fields.
    logout
    login(username: customer.email, password: 'test')

    visit '#customer_ticket_new'

    expect_customer_mask_fields

    # The mask stays correct after another logout/login cycle.
    logout
    login(username: customer.email, password: 'test')

    visit '#customer_ticket_new'

    expect_customer_mask_fields
  end
end
