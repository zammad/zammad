# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Shared Drafts', app: :desktop_view, authenticated_as: :agent1, type: :playwright do
  let(:agent1) { create(:agent, password: 'test', groups: [group]) }
  let(:agent2) { create(:agent, password: 'test', groups: [group]) }
  let(:group)  { create(:group) }

  let(:ticket) do
    create(:ticket, group:).tap do |ticket|
      create(:ticket_article, ticket: ticket)
    end
  end

  before do
    agent2
  end

  def update_button
    page.get_by_role('button', name: 'Update', exact: true)
  end

  def save_as_draft
    page.get_by_role('button', name: 'Drafts & macros').click
    page.get_by_role('menuitem', name: 'Save as draft').click
  end

  def discard_changes
    page.get_by_role('button', name: 'Discard your unsaved changes').click
    page.get_by_role('dialog').get_by_role('button', name: 'Discard changes').click
  end

  # The draft replaces what is typed so far, which asks for a confirmation.
  def apply_draft
    type_in_editor('Text', 'force overwrite dialog')

    page.get_by_role('button', name: 'Draft available').click
    flyout('Apply shared draft').get_by_role('button', name: 'Apply').click
    page.get_by_role('dialog').get_by_role('button', name: 'Overwrite content').click

    expect(editor('Text')).to not_contain_text('force overwrite dialog')
  end

  def add_internal_note_mentioning(text, user)
    add_internal_note_button.click
    type_in_editor('Text', "#{text} ")
    mention_in_editor('Text', user)
    update_button.click

    expect(notification('Ticket updated successfully.')).to be_visible
  end

  def close_tab
    main_sidebar.get_by_role('treeitem').filter(hasText: ticket.title).get_by_role('button', name: 'Close this tab').click
  end

  it 'hands a shared draft over to another agent and back', performs_jobs: true do
    open_desktop_ticket(ticket)

    add_internal_note_button.click
    type_in_editor('Text', 'article text content')
    select_option('Priority', '3 high')
    save_as_draft

    expect(notification('Shared draft has been created successfully.')).to be_visible
    expect(ticket.reload.shared_draft.body).to include('article text content')

    discard_changes
    add_internal_note_mentioning('Can we send this to the customer?', agent2)
    close_tab

    perform_enqueued_jobs

    as_user(agent2) do
      page.get_by_role('button', name: 'Show notifications').click
      page.get_by_role('link', name: "#{agent1.fullname} updated ticket").click

      expect(page).to have_url(%r{/tickets/#{ticket.id}$})
      wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")

      add_internal_note_button.click
      apply_draft

      editor('Text').click
      page.keyboard.press('ControlOrMeta+A')
      type_in_editor('Text', 'article text content - now with modification')

      save_as_draft
      page.get_by_role('dialog').get_by_role('button', name: 'Overwrite draft').click

      wait_until('The shared draft is not overwritten') { ticket.reload.shared_draft.body.include?('article text content - now with modification') }

      discard_changes
      add_internal_note_mentioning("I changed it slightly, it's ready now.", agent1)
      close_tab
    end

    open_desktop_ticket(ticket)

    add_internal_note_button.click
    apply_draft
    update_button.click

    expect(notification('Ticket updated successfully.')).to be_visible
    expect(page.get_by_role('button', name: 'Draft available')).to have_count(0)
    expect(ticket.articles.count).to eq(4)
    expect(ticket.articles.last.body).to include('article text content - now with modification')
  end
end
