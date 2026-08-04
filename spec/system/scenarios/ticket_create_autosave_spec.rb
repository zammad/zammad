# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_update_and_reload_test.rb as a continuous
#   end-to-end scenario: the ticket create form keeps its state (incl. the customer
#   sidebar) across a reload, page title and task follow the subject, and after
#   submitting, the task is not marked as modified. Title stability on dashboard and
#   zoom is covered by scenarios/navigation_and_title_spec.rb.
RSpec.describe 'Scenario > Ticket create autosave and reload', authenticated_as: :authenticate, type: :system do
  let(:group)        { Group.find_by(name: 'Users') }
  let(:agent)        { create(:agent, groups: [group]) }
  let(:customer)     { create(:customer, firstname: 'Nicole', lastname: 'Braun') }
  let(:subject_text) { 'some subject 4 - 123äöü' }

  def authenticate
    customer

    agent
  end

  it 'keeps the create form state across reload and creates a clean task' do
    visit 'ticket/create'

    within(:active_content) do
      find('[name=customer_id_completion]').fill_in with: customer.email

      expect(page).to have_css('.recipientList-entry.js-object')
      first('.recipientList-entry.js-object').click

      find('[name="title"]').fill_in with: subject_text
      find('[data-name="body"]').send_keys 'some body 4 - 123äöü'

      # The selected customer shows up in the sidebar of the create form.
      click '.tabsSidebar-tab[data-tab="customer"]'

      expect(page).to have_css('.sidebar[data-tab="customer"]', text: customer.lastname)
    end

    # Page title and task follow the subject.
    expect(page).to have_title(subject_text)
    expect(page).to have_css('.tasks-navigation .task', text: subject_text)

    # Wait for the autosave, then reload: customer and sidebar state survive.
    wait.until { Taskbar.last&.state.to_s.include?(subject_text) }

    page.refresh

    within(:active_content) do
      click '.tabsSidebar-tab[data-tab="customer"]'

      expect(page).to have_css('.sidebar[data-tab="customer"]', text: customer.lastname)
    end

    expect(page).to have_title(subject_text)

    # Submitting opens the zoom with the rendered article.
    within(:active_content) do
      click '.js-submit'
    end

    expect(page).to have_current_path(%r{#ticket/zoom/}, url: true)
    expect(page).to have_css('.content.active div.ticket-article', text: 'some body 4 - 123äöü')

    # The freshly created ticket task carries no modified marker.
    ticket = Ticket.find_by(title: subject_text)

    expect(page).to have_css(".tasks a[href='#ticket/zoom/#{ticket.id}']")
    expect(page).to have_no_css(".tasks a[href='#ticket/zoom/#{ticket.id}'].is-modified")
  end
end
