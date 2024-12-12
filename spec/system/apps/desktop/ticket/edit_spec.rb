# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Edit', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent)   { create(:agent, password: 'test', groups: [group]) }
  let(:group)   { create(:group) }
  let(:article) { create(:ticket_article, :inbound_email, ticket: ticket) }
  let(:ticket)  { create(:ticket, group:, title: 'Test initial') }

  context 'when editing a ticket', db_strategy: :reset do
    let(:select_field) { create(:object_manager_attribute_select, :shown_screen, name: 'select_field', display: 'Select field', additional_data_options: { options: { '1' => 'Option 1', '2' => 'Option 2', '3' => 'Option 3' } }) }
    let(:text_field)   { create(:object_manager_attribute_text, :shown_screen, name: 'text_field', display: 'Text field') }

    let(:hide_field_in_create) do
      create(:core_workflow,
             :active_and_screen,
             object:  'Ticket',
             screen:  'create_middle',
             perform: {
               'ticket.select_field': {
                 operator: 'hide',
                 hide:     true
               },
             })
    end

    let(:show_field_in_edit) do
      create(:core_workflow,
             :active_and_screen,
             object:  'Ticket',
             screen:  'edit',
             perform: {
               'ticket.select_field': {
                 operator:      'set_mandatory',
                 set_mandatory: true
               },
             })
    end

    before do
      select_field
      text_field
      ObjectManager::Attribute.migration_execute
      hide_field_in_create
      show_field_in_edit
      article

      visit "/ticket/#{ticket.id}"
      wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
    end

    it 'works correctly' do

      #
      # Ticket attributes
      #
      within_form(form_updater_gql_number: 1) do
        find_input('Text field').type('text content')

        click_on 'Update'

        # Check that select field is mandatory.
        expect(page).to have_text('This field is required.')

        find_select('Select field').select_option('Option 2')
      end

      click_on 'Update'

      wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql', number: 1)

      expect(page).to have_text('Ticket updated successfully')
      expect(ticket.reload).to have_attributes(select_field: '2', text_field: 'text content')

      #
      # Tag
      #
      click_on 'Add tag'
      find_autocomplete('Add tag').open.input_element.fill_in(with: 'test_tag').send_keys(:tab)
      wait_for_gql('shared/entities/tags/graphql/mutations/assignment/add.graphql', number: 1)
      expect(page).to have_text('Ticket tag added successfully')
      expect(ticket.tag_list).to include('test_tag')

      #
      # Title
      #
      find('[aria-label="Edit ticket title"]').click
      send_keys ' changed', :enter
      wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql', number: 2)
      expect(page).to have_text('Ticket updated successfully')

      within 'main' do
        expect(page).to have_text('Test initial changed')
      end

      within '#user-taskbar-tabs' do
        expect(page).to have_text('Test initial changed')
      end

      #
      # State
      #
      find_select('State').select_option('closed')

      click_on 'Update'

      wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql', number: 3)

      expect(page).to have_text('Ticket updated successfully')
      expect(ticket.reload.state.name).to eq('closed')

      within '#user-taskbar-tabs' do
        expect(page).to have_css("a[href=\"/desktop/tickets/#{ticket.id}\"] svg[aria-label=\"check-circle-outline\"]")
      end

      #
      # Reorder taskbar
      #
      click_on 'New ticket'
      expect(page).to have_css('label', text: 'Text field')
      expect(page).to have_no_css('label', text: 'Select field')

      within '#user-taskbar-tabs' do
        expect(page).to have_text("Test initial changed\nReceived Call")

        o1 = find('li.draggable', text: 'Test initial changed')
        o2 = find('li.draggable', text: 'Received Call')
        o1.drag_to(o2)

        wait_for_gql('apps/desktop/entities/user/current/graphql/mutations/userCurrentTaskbarItemListPrio.graphql')

        expect(page).to have_text("Received Call\nTest initial changed")
      end

      logout

      login(username: agent.login, password: 'test')

      within '#user-taskbar-tabs' do
        expect(page).to have_text("Received Call\nTest initial changed")
      end
    end
  end
end
