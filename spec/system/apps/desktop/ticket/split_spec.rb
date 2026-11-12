# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Split, Link and Subscribe', app: :desktop_view, authenticated_as: :agent1, type: :playwright do
  let(:agent1)  { create(:agent, password: 'test', groups: [group]) }
  let!(:agent2) { create(:agent, password: 'test', groups: [group]) }
  let(:group)   { create(:group) }

  let!(:ticket) do
    create(:ticket, group:).tap do |ticket|
      create(:ticket_article, :inbound_email, ticket: ticket, body: 'Hello, I have a question.')
      create(:ticket_article, :inbound_email, ticket: ticket, body: 'And a follow-up question.')
    end
  end

  def related_tickets
    content_sidebar.get_by_role('group', name: 'Related tickets')
  end

  it 'splits an article into a linked ticket and notifies its subscriber', performs_jobs: true do
    open_desktop_ticket(ticket)

    ticket_article('And a follow-up question.').get_by_role('button', name: 'Action menu button').click
    page.get_by_role('menuitem', name: 'Split').click
    wait_for_form_to_settle('ticket-create')
    page.get_by_role('button', name: 'Create', exact: true).click

    expect(notification('Ticket has been created successfully.')).to be_visible

    split_ticket = Ticket.last
    wait_for_form_to_settle("form-ticket-edit-#{split_ticket.id}")

    select_option('Owner', agent2.fullname)
    content_sidebar.get_by_role('switch', name: 'Subscribe me').click
    page.get_by_role('button', name: 'Update', exact: true).click

    expect(notification('Ticket updated successfully.')).to be_visible
    expect(related_tickets).to contain_text('Parent')
    expect(related_tickets.get_by_role('link', name: ticket.title, exact: true)).to be_visible

    open_desktop_ticket(ticket)

    expect(related_tickets).to contain_text('Child')
    expect(related_tickets.get_by_role('link', name: split_ticket.title, exact: true)).to be_visible

    as_user(agent2) do
      open_desktop_ticket(split_ticket)

      add_internal_note_button.click
      type_in_editor('Text', 'Some reply.')
      page.get_by_role('button', name: 'Update', exact: true).click

      expect(notification('Ticket updated successfully.')).to be_visible
    end

    perform_enqueued_jobs

    page.get_by_role('button', name: 'Show notifications').click

    expect(page.get_by_text("#{agent2.fullname} updated ticket")).to be_visible
  end
end
