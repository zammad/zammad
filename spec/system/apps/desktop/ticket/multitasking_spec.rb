# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Multitasking', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:agent)        { create(:agent, groups: [group]) }
  let(:group)        { create(:group) }
  let(:ticket)       { create(:ticket, group:, title: 'Test initial') }
  let(:other_ticket) { create(:ticket, group:, title: 'Other ticket') }
  let(:customer)     { create(:customer, :with_org) }

  before do
    10.times do |i|
      travel 1.day
      create(:ticket_article, ticket: ticket, body: "some message #{i}")
    end

    ticket.update! title: 'Changed title'

    10.times do
      travel 1.day
      create(:ticket_article, ticket: ticket)
    end
  end

  def open_ticket(ticket)
    open_desktop("/tickets/#{ticket.id}")
    wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
  end

  def switch_to_tab(title)
    main_sidebar.get_by_role('link', name: title).click
  end

  # A ticket opens scrolled to its newest article.
  def wait_for_newest_article
    expect(main_content.get_by_text(ticket.articles.last.body).last).to be_in_viewport
  end

  # The scroll to the newest article swaps the headers, which closes any open popover. Locators
  #   do not tell the headers apart: the one swapped out only turns inert.
  def wait_for_header_swap
    full_header = '[data-test-id=ticket-detail-top-bar-full-details]'
    page.wait_for_function('(header) => document.querySelector(`${header}[inert], ${header} [inert]`)', arg: full_header)
  end

  def expect_scroll_offset(element, offset)
    expect(offset).to be_positive
    wait_for_scroll_offset(element, offset)
  end

  it 'history flyout stays around when switching between taskbars' do
    open_ticket(ticket)

    wait_for_header_swap

    content_sidebar.get_by_role('button', name: 'Action menu button').click
    page.get_by_role('menuitem', name: 'History').click
    wait_for_query('ticketHistory')

    history_entry = flyout('History').get_by_role('time').last
    history_entry.scroll_into_view_if_needed
    preserved_scroll_offset = scroll_offset(history_entry)

    main_sidebar.get_by_role('link', name: 'New ticket').click
    wait_for_form_to_settle('ticket-create')
    fill_field('Title', 'Example Ticket Title')
    search_for_option('Customer', customer.email, option: customer.fullname)
    type_in_editor('Text', 'some text')
    page.get_by_role('button', name: 'Create', exact: true).click
    expect(notification('Ticket has been created successfully')).to be_visible

    switch_to_tab(ticket.title)

    expect(flyout('History')).to be_visible
    expect_scroll_offset(history_entry, preserved_scroll_offset)
  end

  it 'keeps new article form pinned and other ticket scrolling in place' do
    open_ticket(ticket)
    open_ticket(other_ticket)

    add_internal_note_button.click
    type_in_editor('Text', 'Call content here')
    page.get_by_role('button', name: 'Pin this panel').click

    switch_to_tab(ticket.title)
    wait_for_newest_article

    article = main_content.get_by_text('some message 9', exact: true)
    article.scroll_into_view_if_needed
    preserved_scroll_offset = scroll_offset(article)

    switch_to_tab(other_ticket.title)

    expect(editor('Text')).to contain_text('Call content here')
    page.get_by_role('button', name: 'Unpin this panel').click
    page.get_by_role('button', name: 'Update', exact: true).click

    expect(notification('Ticket updated successfully.')).to be_visible
    expect(main_content.get_by_text('Call content here', exact: true)).to be_visible

    switch_to_tab(ticket.title)

    expect_scroll_offset(article, preserved_scroll_offset)
  end
end
