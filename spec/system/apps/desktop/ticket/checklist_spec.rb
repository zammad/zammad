# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Checklist', app: :desktop_view, authenticated_as: :agent, current_user_id: 1, type: :playwright do
  let(:agent)       { create(:agent, groups: [group]) }
  let(:other_agent) { create(:agent, password: 'test', groups: [group]) }
  let(:customer)    { create(:customer) }
  let(:group)       { create(:group) }

  let(:checklist_main_items) do
    [
      'Buy desk and chair',
      'Provide date and time of first working day',
      'Allocate a bike parking slot',
      'Create an access card for the building',
      'IT to-dos',
      'Schedule a meeting with the complete department in the first week (duration at least 1 hour).'
    ]
  end

  let(:checklist_sub_items) do
    [
      'Buy laptop',
      'Buy mobile phone',
      'Install Linux on laptop',
      'Create account in Zammad'
    ]
  end

  let(:checklist_template_main) { create(:checklist_template, name: 'Main Onboarding Checklist', items: checklist_main_items) }
  let(:checklist_template_sub)  { create(:checklist_template, name: 'IT Onboarding Checklist', items: checklist_sub_items) }

  let(:main_title) { 'Main Onboarding' }
  let(:it_title)   { 'IT Onboarding' }

  before do
    checklist_template_main && checklist_template_sub # make checklists creation interactive once it's available in newtechstack
    other_agent
  end

  it 'works as expected' do
    open_desktop('/')

    create_ticket(main_title, agent, checklist_template_main)
    main_ticket = Ticket.last
    create_ticket(it_title, other_agent, checklist_template_sub)
    it_ticket = Ticket.last

    add_sub_ticket_to_main_checklist(it_ticket)
    add_internal_note('Some notes about the new employee onboarding.')

    check_all_checkboxes(main_ticket)
    expect_referenced_ticket_state(it_ticket, 'open')
    try_closing
    expect(checklist_badge).to contain_text('5 of 6')

    as_user(other_agent) do
      open_desktop_ticket(it_ticket)

      add_internal_note('Some notes about the new employee onboarding.', mention: agent)
      check_all_checkboxes(it_ticket)
      close_ticket

      wait_until('The IT ticket is not closed') { it_ticket.reload.state.name == 'closed' }
    end

    expect_referenced_ticket_state(it_ticket, 'closed')
    expect(checklist_badge).to have_count(0)

    # The form kept the state of the first attempt.
    content_sidebar.get_by_role('button', name: 'Ticket', exact: true).click
    expect(selected_options('State')).to have_text('closed')
    page.get_by_role('button', name: 'Update', exact: true).click

    wait_until('The main ticket is not closed') { main_ticket.reload.state.name == 'closed' }
  end

  context 'when editing a checklist item that wraps' do
    let(:ticket)    { create(:ticket, group:) }
    let(:item_text) { Array.new(4, 'A rather long checklist item').join(' ') }

    before do
      create(:checklist_item, checklist: create(:checklist, :empty, ticket:), text: item_text)

      open_desktop_ticket(ticket)
      open_checklist
    end

    it 'keeps the text wrapped, with the caret where it was clicked' do
      content_sidebar.get_by_role('button', name: 'Start editing').filter(hasText: item_text).click(position: { x: 5, y: 5 })

      textbox = content_sidebar.get_by_role('textbox', name: 'Text or ticket identifier')
      expect(textbox).to be_focused

      line_height = textbox.evaluate('(textbox) => parseFloat(getComputedStyle(textbox).lineHeight)')

      expect(textbox.evaluate('(textbox) => textbox.selectionStart')).to be < 'A rather'.length
      expect(textbox.evaluate('(textbox) => textbox.getBoundingClientRect().height')).to be > line_height
    end
  end

  def create_ticket(title, owner, checklist_template)
    main_sidebar.get_by_role('link', name: 'New ticket').click
    wait_for_form_to_settle('ticket-create')

    fill_field('Title', title)
    search_for_option('Customer', customer.email, option: customer.fullname)
    select_option('Owner', owner.fullname)
    type_in_editor('Text', 'Onboarding ticket')
    page.get_by_role('button', name: 'Create', exact: true).click

    expect(notification('Ticket has been created successfully')).to be_visible

    open_checklist

    content_sidebar.get_by_role('button', name: 'Add from a template').click
    page.get_by_role('button', name: checklist_template.name).click

    expect(content_sidebar.get_by_role('listitem')).to have_count(checklist_template.items.count)
  end

  def open_checklist
    content_sidebar.get_by_role('button', name: 'Checklist', exact: true).click
  end

  # Both ticket headers carry the badge, the one swapped out only turns inert.
  def checklist_badge
    main_content.get_by_role('button', name: 'Open checklist').filter(visible: true)
  end

  def add_sub_ticket_to_main_checklist(sub_ticket)
    main_sidebar.get_by_role('link', name: main_title).click
    open_checklist

    content_sidebar.get_by_role('button', name: 'Start editing').filter(hasText: 'IT to-dos').click
    content_sidebar.get_by_role('textbox', name: 'Text or ticket identifier').fill("#{Setting.get('ticket_hook')}#{Setting.get('ticket_hook_divider')}#{sub_ticket.number}")
    content_sidebar.get_by_role('button', name: 'Save changes').click

    expect(content_sidebar.get_by_role('link', name: sub_ticket.title)).to be_visible
  end

  def add_internal_note(text, mention: nil)
    add_internal_note_button.click
    type_in_editor('Text', "#{text} ")
    mention_in_editor('Text', mention) if mention

    page.get_by_role('button', name: 'Update', exact: true).click

    expect(notification('Ticket updated successfully.')).to be_visible
  end

  # A ticket item has no checkbox, its ticket's state checks it.
  def check_all_checkboxes(ticket)
    open_checklist

    checkboxes = content_sidebar.get_by_role('checkbox')
    expect(checkboxes.first).to be_visible

    checkboxes.all.each(&:check)

    # A checkbox is checked before the server knows, and closing the ticket asks the server.
    wait_until('The checklist items are not checked') { ticket.reload.checklist.items.where(ticket_id: nil).incomplete.none? }
  end

  def expect_referenced_ticket_state(ticket, state)
    status = content_sidebar.get_by_role('link', name: ticket.title).get_by_role('status')

    expect(status).to have_attribute('aria-roledescription', "(ticket status: #{state})")
  end

  def try_closing
    close_ticket

    page.get_by_role('dialog', name: 'Incomplete ticket checklist').get_by_role('button', name: 'Yes, open the checklist').click
  end

  def close_ticket
    content_sidebar.get_by_role('button', name: 'Ticket', exact: true).click
    select_option('State', 'closed')
    page.get_by_role('button', name: 'Update', exact: true).click
  end
end
