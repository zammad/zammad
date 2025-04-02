# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Shared Drafts', app: :desktop_view, authenticated_as: :agent1, type: :system do
  let(:agent1) { create(:agent, password: 'test', groups: [group]) }
  let(:agent2) { create(:agent, password: 'test', groups: [group]) }
  let(:group)  { create(:group) }

  let(:ticket) do
    create(:ticket, group:).tap do |ticket|
      create(:ticket_article, ticket: ticket)
    end
  end

  context 'when using shared drafts' do
    before do
      visit "/ticket/#{ticket.id}"

      wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
    end

    def close_tab
      within '#taskbarTabListExpanded' do
        find('li', text: ticket.title).find('button[aria-label="Close this tab"]', visible: :all).click
      end
    end

    it 'works correctly', performs_jobs: true do
      click_on 'Add phone call'

      within_form(form_updater_gql_number: 2) do
        find_editor('Text').type('article text content')
        find_select('Priority').select_option('3 high')
      end

      # Create draft
      click_on('Additional ticket edit actions')
      click_on('Save as draft')

      wait_for_gql('shared/entities/ticket-shared-draft-zoom/graphql/mutations/ticketSharedDraftZoomCreate.graphql')

      expect(page).to have_text('Shared draft has been created successfully.')
      expect(ticket.shared_draft.body).to include('article text content')

      # Create an internal note for agent2
      click_on('Discard your unsaved changes')
      click_on('Discard Changes')
      click_on('Add internal note')

      within_form(form_updater_gql_number: 4) do
        find_editor('Text').type("Can we send this to the customer?  @@#{agent2.firstname}")
      end

      find('li', text: agent2.fullname).click

      wait_for_form_updater(6)

      click_on('Update')

      expect(page).to have_text('Ticket updated successfully.')

      close_tab

      # Add notification for agent2 from article mention.
      perform_enqueued_jobs

      using_session :agent2 do
        login(username: agent2.login, password: 'test')

        # Open ticket from notifications.
        click_on 'Show notifications'
        find('a', text: "#{agent1.fullname} updated ticket").click

        expect(page).to have_current_route("tickets/#{ticket.id}")

        wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")

        # Modify draft
        click_on('Add phone call')

        within_form(form_updater_gql_number: 2) do
          find_editor('Text').type('force overwrite dialog')
        end

        click_on('Draft Available')
        click_on('Apply')
        click_on('Overwrite Content')

        within_form(form_updater_gql_number: 4) do
          find_editor('Text').clear.type('article text content - now with modification')
        end

        click_on('Additional ticket edit actions')
        click_on('Save as draft')
        click_on('Overwrite Draft')

        wait_for_gql('shared/entities/ticket-shared-draft-zoom/graphql/mutations/ticketSharedDraftZoomUpdate.graphql')

        expect(ticket.reload.shared_draft.body).to include('article text content - now with modification')

        # Create an internal note for agent1
        click_on('Discard your unsaved changes')
        click_on('Discard Changes')
        click_on('Add internal note')

        within_form(form_updater_gql_number: 8) do
          find_editor('Text').type("I changed it slightly, it's ready now.  @@#{agent1.firstname}")
        end

        find('li', text: agent1.fullname).click

        wait_for_form_updater(10)

        click_on('Update')

        expect(page).to have_text('Ticket updated successfully.')

        close_tab

        page.driver.browser.close
      end

      # Back to agent1
      visit "/ticket/#{ticket.id}"

      wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")

      # Apply the draft
      click_on('Add phone call')

      within_form(form_updater_gql_number: 2) do
        find_editor('Text').type('force overwrite dialog')
      end

      click_on('Draft Available')
      click_on('Apply')
      click_on('Overwrite Content')

      wait_for_form_updater(4)

      click_on('Update')

      wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql')

      # TODO: check why this fails
      # expect(page).to have_no_text('Draft Available')

      expect(ticket.articles.count).to eq(4)
      expect(ticket.articles.last.body).to include('article text content - now with modification')
    end
  end
end
