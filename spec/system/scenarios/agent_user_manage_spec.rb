# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_user_manage_test.rb as end-to-end scenarios:
#   creating a brand new customer inline via the js-objectNew entry of the customer
#   completion (in the create mask and in the zoom customer change modal) and
#   finding the created customer again through the search in a fresh form.
RSpec.describe 'Scenario > Inline customer creation', authenticated_as: :authenticate, type: :system do
  let(:group)          { Group.find_by(name: 'Users') }
  let(:agent)          { create(:agent, groups: [group]) }
  let(:customer_email) { "inline.customer.#{SecureRandom.hex(4)}@example.com" }

  def authenticate
    agent
  end

  def create_customer_inline(email)
    find('[name=customer_id_completion]').click
    find('[name=customer_id_completion]').send_keys(:arrow_down)

    click '.recipientList-entry.js-objectNew'

    find('.modal input[name="firstname"]').fill_in with: 'Inline'
    find('.modal input[name="lastname"]').fill_in with: 'Customer'
    find('.modal input[name="email"]').fill_in with: email

    # The change customer modal embeds the new user form incl. its own submit
    #   button - target the button inside the same form as the user fields.
    find('.modal input[name="email"]').ancestor('form').find('button.js-submit').click
  end

  def expect_selected_customer(email, scope: '.newTicket')
    wait.until { find("#{scope} input[name=\"customer_id\"]", visible: :all).value.match?(%r{^\d+$}) }

    expect(find("#{scope} [name=customer_id_completion]").value).to include('Inline').and include('Customer').and include(email)
  end

  it 'creates a customer inline in the create mask and finds it again afterwards' do
    visit 'ticket/create'

    within(:active_content) do
      create_customer_inline(customer_email)

      expect_selected_customer(customer_email)
    end

    # A fresh create mask starts empty and finds the new customer via search.
    visit 'dashboard'
    visit 'ticket/create'

    within(:active_content) do
      expect(find('input[name="customer_id"]', visible: :all).value).to be_empty
      expect(find('[name=customer_id_completion]').value).to be_empty

      find('[name=customer_id_completion]').fill_in with: customer_email

      expect(page).to have_css('.recipientList-entry.js-object')
      first('.recipientList-entry.js-object').click

      expect_selected_customer(customer_email)
    end
  end

  context 'with an existing ticket' do
    let(:ticket) { create(:ticket, group:, customer: create(:customer, firstname: 'Nicole', lastname: 'Braun')) }

    def authenticate
      ticket

      agent
    end

    it 'creates a customer inline in the zoom customer change modal' do
      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        click '.tabsSidebar-tab[data-tab="customer"]'

        expect(page).to have_css('.sidebar[data-tab="customer"]', text: 'Nicole Braun')

        click '.tabsSidebar-tab[data-tab="ticket"]'
        find('[data-tab="ticket"] .js-actions').click
        click '[data-type="customer-change"]'
      end

      create_customer_inline(customer_email)

      expect_selected_customer(customer_email, scope: '.modal')

      find('.modal button.js-submit').click

      expect(page).to have_no_css('.modal')

      within(:active_content) do
        click '.tabsSidebar-tab[data-tab="customer"]'

        expect(page).to have_css('.sidebar[data-tab="customer"]', text: customer_email)
      end
    end
  end
end
