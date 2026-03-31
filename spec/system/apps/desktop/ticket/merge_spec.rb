# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Merge', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent)   { create(:agent, groups: [group]) }
  let(:group)   { create(:group) }

  let!(:ticket) do
    create(:ticket, group:).tap do |ticket|
      create(:ticket_article, :inbound_email, ticket:, body: 'Hello, I have a question.')
    end
  end

  let!(:duplicate_ticket) do
    create(:ticket, group:).tap do |ticket|
      create(:ticket_article, :inbound_email, ticket:, body: 'Hello, I have the same question again.')
    end
  end

  context 'when using ticket merge' do

    let!(:macro) do
      create(:macro,
             name:            'Ticket duplicate',
             perform:         {
               'article.note' => {
                 'body' => "This ticket of \#{ticket.customer.fullname} was merged to the original ticket.", 'internal' => 'true',
                 'subject' => 'duplicate ticket'
               },
               'ticket.tags'  => { 'operator' => 'add', 'value' => 'duplicate' }
             },
             ux_flow_next_up: 'none')
    end

    before do
      visit "/tickets/#{duplicate_ticket.id}"
      wait_for_form_to_settle("form-ticket-edit-#{duplicate_ticket.id}")
    end

    it 'works correctly', performs_jobs: true, retry: 0 do

      within '#ticketSidebar' do
        click_on('Action menu button')
      end

      click_on('Merge')

      within_form do
        find_autocomplete('Target ticket').search_for_option(ticket.number)
      end

      within '#flyout-ticket-merge' do
        click_on('Merge')
      end

      expect(page).to have_text('Ticket merged successfully')

      within '#ticketSidebar' do
        expect(page).to have_text('Child')
        click_on(duplicate_ticket.title)
      end

      expect(find('.inner-article-body')).to have_text('merged')

      click_on('Additional ticket edit actions')
      click_on(macro.name)

      within '#ticketSidebar' do
        expect(page).to have_text('duplicate')
      end

      expect(page).to have_text("This ticket of #{duplicate_ticket.customer.fullname} was merged to the original ticket.")
    end
  end
end
