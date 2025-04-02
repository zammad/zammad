# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Split, Link and Subscribe', app: :desktop_view, authenticated_as: :agent1, type: :system do
  let(:agent1)  { create(:agent, password: 'test', groups: [group]) }
  let!(:agent2) { create(:agent, password: 'test', groups: [group]) }
  let(:group)   { create(:group) }

  let!(:ticket) do
    create(:ticket, group:).tap do |ticket|
      create(:ticket_article, :inbound_email, ticket: ticket, body: 'Hello, I have a question.')
      create(:ticket_article, :inbound_email, ticket: ticket, body: 'And a follow-up question.')
    end
  end

  context 'when using ticket split, link and subscribe' do
    before do
      visit "/tickets/#{ticket.id}"

      wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
    end

    it 'works correctly', performs_jobs: true, retry: 0 do
      # Split ticket.
      within "#article-#{ticket.articles.last.id}" do
        click_on('Action menu button')
      end

      click_on('Split')

      wait_for_form_to_settle('ticket-create')

      click_on('Create')

      expect(page).to have_text('Ticket has been created successfully.')

      # Make changes and subscribe.
      within_form(form_updater_gql_number: 2) do
        find_select('Owner').select_option(agent2.fullname)
        find_toggle('Subscribe me').toggle_on
      end

      click_on('Update')

      expect(page).to have_text('Ticket updated successfully.')

      # Check links.
      within '#ticket-links' do
        expect(page).to have_text('Parent').and(have_text(ticket.title))
      end

      visit "/tickets/#{ticket.id}"

      wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")

      within '#ticket-links' do
        expect(page).to have_text('Child').and(have_text(Ticket.last.title))
      end

      # Create reply with another agent.
      using_session :agent2 do
        login(username: agent2.login, password: 'test')

        visit "/tickets/#{Ticket.last.id}"

        wait_for_form_to_settle("form-ticket-edit-#{Ticket.last.id}")

        click_on('Add reply')

        within_form(form_updater_gql_number: 2) do
          find_editor('Text').type('Some reply.')
        end

        click_on('Update')

        expect(page).to have_text('Ticket updated successfully.')

        page.driver.browser.close
      end

      # Check that notification was created.
      perform_enqueued_jobs

      click_on 'Show notifications'

      expect(page).to have_text("#{agent2.fullname} updated ticket")
    end
  end
end
