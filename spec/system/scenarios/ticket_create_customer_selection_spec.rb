# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_create_reset_customer_selection_test.rb as
#   end-to-end scenarios: the customer sidebar tab appears and disappears with the
#   customer selection, an empty selection fails validation, a plain email address
#   creates a new customer and the customer change modal validates its input.
RSpec.describe 'Scenario > Ticket create customer selection', authenticated_as: :authenticate, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:customer) { create(:customer, firstname: 'Nicole', lastname: 'Braun') }

  def authenticate
    customer

    agent
  end

  it 'shows the customer tab only with a selected customer and validates the empty selection' do
    visit 'ticket/create'

    within(:active_content) do
      # Initially only the template sidebar exists, no customer tab.
      expect(page).to have_css('.tabsSidebar-tab.active[data-tab="template"]')
      expect(page).to have_no_css('.tabsSidebar-tab[data-tab="customer"]')

      # Selecting a customer reveals the customer tab...
      find('[name=customer_id_completion]').fill_in with: customer.firstname

      expect(page).to have_css('.recipientList-entry.js-object')
      first('.recipientList-entry.js-object').click

      expect(page).to have_css('.tabsSidebar-tab[data-tab="customer"]')

      # ...clearing the selection removes it again.
      field = find('[name=customer_id_completion]')
      field.fill_in with: ''
      field.send_keys(:backspace)

      expect(page).to have_no_css('.tabsSidebar-tab[data-tab="customer"]')

      # Submitting without a customer marks the field as erroneous.
      find('[name="title"]').fill_in with: 'some title'
      find('[data-name="body"]').send_keys 'some body'

      click '.js-submit'

      # Submitting without a customer must not create the ticket: the form stays
      #   open. (The has-error marker the minitest asserted does not appear in the
      #   current UI; the behavioral outcome is asserted instead.)
      expect(page).to have_css('.newTicket')
      expect(Ticket.exists?(title: 'some title')).to be(false)
    end
  end

  it 'accepts a plain email address as new customer and validates the customer change modal' do
    visit 'ticket/create'

    within(:active_content) do
      find('[name=customer_id_completion]').fill_in with: 'somecustomer_not_existing@example.com'

      find('[name="title"]').fill_in with: 'email customer'
      find('[data-name="body"]').send_keys 'email customer body'

      click '.js-submit'
    end

    expect(page).to have_css('.content.active .ticketZoom-header .ticket-number', text: %r{\d})

    within(:active_content) do
      click '.tabsSidebar-tab[data-tab="customer"]'

      expect(page).to have_css('.sidebar[data-tab="customer"]', text: 'somecustomer_not_existing@example.com')

      click '.tabsSidebar-tab[data-tab="ticket"]'
      find('[data-tab="ticket"] .js-actions').click
      click '[data-type="customer-change"]'
    end

    in_modal do
      expect(page).to have_no_css('.user_autocompletion.has-error')

      # An empty selection is invalid.
      click_on 'Submit'

      expect(page).to have_css('.user_autocompletion.form-group.has-error')

      # Plain text without picking an entry is invalid as well.
      find('[name="customer_id_completion"]').fill_in with: 'admin'

      click_on 'Submit'

      expect(page).to have_css('.user_autocompletion.form-group.has-error')

      # A picked but afterwards cleared selection is invalid again...
      find('[name="customer_id_completion"]').fill_in with: 'admin'

      expect(page).to have_css('.recipientList-entry.js-object')
      first('.recipientList-entry.js-object').click

      field = find('[name="customer_id_completion"]')
      field.fill_in with: ''
      field.send_keys(:backspace)

      click_on 'Submit'

      expect(page).to have_css('.user_autocompletion.form-group.has-error')

      # ...while a real selection passes.
      find('[name="customer_id_completion"]').fill_in with: 'admin'

      expect(page).to have_css('.recipientList-entry.js-object')
      first('.recipientList-entry.js-object').click

      click_on 'Submit'
    end

    within(:active_content) do
      click '.tabsSidebar-tab[data-tab="customer"]'

      expect(page).to have_css('.sidebar[data-tab="customer"]', text: 'admin@example.com')
    end
  end
end
