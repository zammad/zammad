# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Checklist', app: :desktop_view, authenticated_as: :agent, current_user_id: 1, type: :system do
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
    create_ticket(main_title, agent, checklist_template_main)
    create_ticket(it_title, other_agent, checklist_template_sub)

    add_sub_ticket_to_main_checklist
    add_article_to_main_ticket

    check_all_checkboxes
    verify_referenced_ticket_state('open')
    try_closing
    verify_checklist_badge

    using_session :agent2 do
      login(username: other_agent.login, password: 'test')

      find('[role="searchbox"]').fill_in(with: it_title.first(5))
      click_on it_title
      add_article_to_it_ticket
      check_all_checkboxes
      close_ticket
      wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql', number: 2)

      wait.until do
        Ticket.last.reload.state.name == 'closed'
      end

      page.driver.browser.close
    end

    close_and_verify
  end

  def create_ticket(title, owner, checklist_template)
    visit '/ticket/create'
    wait_for_form_to_settle('ticket-create')

    within_form(form_updater_gql_number: 1) do
      find_input('Title').type(title)
      find_input('Customer').search_for_option(customer.email, label: customer.fullname)
      find_select('Owner').select_option(owner.fullname)
      find_editor('Text').type('Onboarding ticket')
    end

    click_on 'Create'

    open_checklist

    click_on 'Add From a Template'
    click_on checklist_template.name
  end

  def open_checklist
    find('button[aria-label="Checklist"]').click
  end

  def ticket_hook(ticket)
    ticket_hook         = Setting.get('ticket_hook')
    ticket_hook_divider = Setting.get('ticket_hook_divider')

    "#{ticket_hook}#{ticket_hook_divider}#{ticket.number}"
  end

  def add_sub_ticket_to_main_checklist
    click_on main_title
    open_checklist

    find('span', text: 'IT to-dos').click
    find('#ticketSidebar input').fill_in with: ticket_hook(Ticket.last)
    find('#ticketSidebar button[aria-label="Save changes"]').click
    wait_for_gql('apps/desktop/pages/ticket/graphql/mutations/ticketChecklistItemUpsert.graphql')
  end

  def add_article_to_main_ticket
    click_on('Add reply')
    find_editor('Text').type('Some notes about the new employee onboarding.')

    click_on 'Update'
    wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql')
  end

  def add_article_to_it_ticket
    click_on('Add reply')
    find_editor('Text').type('Some notes about the new employee onboarding.')
    find_editor('Text').type("ping @@#{agent.firstname}")
    find('li', text: agent.fullname).click
    wait_for_form_updater

    click_on 'Update'
    wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql')
  end

  def check_all_checkboxes
    open_checklist

    checkboxes = find_all('#ticketSidebar input[type=checkbox]', visible: :all)

    checkboxes.each do |elem|
      elem.sibling('span').click
    end

    wait_for_gql('apps/desktop/pages/ticket/graphql/mutations/ticketChecklistItemUpsert.graphql', number: checkboxes.count)
  end

  def verify_referenced_ticket_state(state)
    expect(page).to have_css('#ticketSidebar li svg') do |elem|
      elem[:'aria-labelledby'] == "ticket-#{Ticket.maximum(:id)}" && elem[:'aria-roledescription'] == "(ticket status: #{state})"
    end
  end

  def try_closing
    close_ticket

    expect(page).to have_text('Incomplete Ticket Checklist')

    click_on 'Yes, open the checklist'
  end

  def verify_checklist_badge
    expect(page).to have_text("CHECKED\n5 of 6")
  end

  def close_ticket
    find('button[aria-label="Ticket"]').click

    find_select('State').select_option('closed')

    click_on 'Update'
  end

  def close_and_verify
    verify_referenced_ticket_state('closed')
    expect(page).to have_no_text('CHECKED')
    close_ticket
    wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql', number: 2)

    wait.until do
      Ticket.second_to_last.reload.state.name == 'closed'
    end
  end
end
