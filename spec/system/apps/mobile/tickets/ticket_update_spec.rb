# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile/examples/core_workflow_examples'

RSpec.describe 'Mobile > Ticket > Update', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:group_2)  { create(:group, name: 'Group 2') }
  let(:owner)    { User.find_by(email: 'agent1@example.com') }
  let(:agent)    { create(:agent, groups: [group, group_2]) }
  let(:ticket)   { create(:ticket, title: 'Ticket Title', owner: owner, group: group) }

  def find_outer(label)
    find('.formkit-outer', text: label)
  end

  def find_by_label(label)
    state_selector = find_outer(label)
    state_selector.find('output', visible: :all)
  end

  def select_option(output, option)
    output.click
    click('[role="option"]', text: option)
  end

  def submit_form
    find_button('Save ticket').click
    wait_for_gql('apps/mobile/pages/ticket/graphql/mutations/update.graphql')
  end

  #  - policy says that only agent with "read" access, but not "change" access can view this
  #  - if user can view ticket, he can also change it
  context 'when user cannot update ticket', authenticated_as: :viewer do
    let(:organization) { create(:organization, shared: true) }
    let(:viewer) do
      user = create(:agent, groups: [group], organization: organization)
      user.group_names_access_map = {
        group.name => 'read',
      }
      user.save!
      user
    end
    let(:owner)    { create(:customer, groups: [group], organization: organization) }
    let(:ticket)   { create(:ticket, owner: owner, group: group, organization: organization) }
    let(:tags) do
      [
        Tag::Item.lookup_by_name_and_create('foo'),
        Tag::Item.lookup_by_name_and_create('bar'),
      ]
    end

    before do
      create(:tag, o: ticket, tag_item: tags.first)
      create(:tag, o: ticket, tag_item: tags.last)
    end

    it 'does not show "save" button, but shows form as menu with sections' do
      visit "/tickets/#{ticket.id}/information"

      expect(page).to have_no_button('Save ticket')
      expect(page).to have_no_css('output', text: 'Tags')
      expect(find('section', text: %r{Tags})).to have_text('foo, bar')
      expect(find('section', text: %r{Group})).to have_text(ticket.group.name)
      expect(find('section', text: %r{State})).to have_text(ticket.state.name)
    end
  end

  context 'when user can update ticket' do
    context 'when there are no custom object attributes' do
      it 'can edit ticket in ideal scenario without object attributes' do
        visit "/tickets/#{ticket.id}/information"

        wait_for_form_to_settle('form-ticket-edit')

        expect(page.find_button('Save ticket', disabled: true).disabled?).to be(true)

        within_form(form_updater_gql_number: 1) do
          title = find_input('Ticket title')
          expect(title).to have_value('Ticket Title')
          title.type('New Title')

          state = find_select('State')
          expect(state).to have_selected_option(ticket.state.name)
          state.select_option('closed')
          expect(state).to have_selected_option('closed')

          priority = find_select('Priority')
          expect(priority).to have_selected_option(ticket.priority.name)
          priority.select_option('3 high')
          expect(priority).to have_selected_option('3 high')
        end

        ticket.reload

        expect(ticket.title).not_to eq('New Title')
        expect(ticket.state.name).not_to eq('closed')
        expect(ticket.priority.name).not_to eq('3 high')

        submit_form

        ticket.reload

        expect(ticket.title).to eq('New Title')
        expect(ticket.state.name).to eq('closed')
        expect(ticket.priority.name).to eq('3 high')
      end

      it 'can reset the owner' do
        visit "/tickets/#{ticket.id}/information"

        wait_for_form_to_settle('form-ticket-edit')

        within_form(form_updater_gql_number: 1) do
          owner_field = find_select('Owner')
          expect(owner_field).to have_selected_option(owner.fullname)

          owner_field.clear_selection
          expect(owner_field).to have_no_selected_option(owner.fullname)
        end

        submit_form

        ticket.reload

        expect(ticket.owner.id).to be(1)
      end

      it 'changing ticket state to pending requires pending time', time_zone: 'Europe/London' do
        visit "/tickets/#{ticket.id}/information"

        wait_for_form_to_settle('form-ticket-edit')

        expect(page).to have_no_css('label', text: 'Pending until')

        date = 1.day.from_now.beginning_of_minute

        within_form(form_updater_gql_number: 1) do
          find_select('State').select_option('pending reminder')

          date_input = find_datepicker('Pending till')
          expect(date_input.input_element.value).to eq('')

          expect(find_button('Save ticket')).to have_css('[role="status"][aria-label="Validation failed"]')

          date_input.type_datetime(date)
        end

        ticket.reload
        expect(ticket.pending_time).to be_nil

        submit_form

        ticket.reload
        expect(ticket.pending_time.localtime).to eq(date)
      end

      it 'can save form on another page' do
        visit "/tickets/#{ticket.id}/information"

        wait_for_form_to_settle('form-ticket-edit')

        within_form(form_updater_gql_number: 1) do
          find_input('Ticket title').type('New Title')
        end

        click('button', text: 'Customer')

        submit_form

        ticket.reload
        expect(ticket.title).to eq('New Title')
      end
    end

    context 'when changing group' do
      it 'owner depends on group' do
        visit "/tickets/#{ticket.id}/information"

        wait_for_form_to_settle('form-ticket-edit')

        within_form(form_updater_gql_number: 1) do
          owner_field = find_select('Owner')
          expect(owner_field).to have_selected_option(owner.fullname)

          group = find_select('Group')
          group.clear_selection

          expect(owner_field).to have_no_selected_option(owner.fullname)

          group.select_option('Users')
          owner_field.select_option(agent.fullname)
          expect(owner_field).to have_selected_option(agent.fullname)
        end

        ticket.reload
        expect(ticket.owner.id).not_to eq(agent.id)

        submit_form

        ticket.reload
        expect(ticket.owner.id).to eq(agent.id)
      end
    end

    context 'when there are custom object attributes' do
      it 'if attribute is required, block submit button, when value is empty', db_strategy: :reset do
        screens = { edit: { 'ticket.agent': { shown: true, required: true } } }
        attribute = create_attribute(
          :object_manager_attribute_text,
          object_name: 'Ticket',
          display:     'Custom Text',
          screens:     screens
        )
        ticket[attribute.name] = 'Attribute Text'
        ticket.save!
        visit "/tickets/#{ticket.id}/information"

        wait_for_form_to_settle('form-ticket-edit')

        within_form(form_updater_gql_number: 1) do
          attribute_field = find_input(attribute.display)
          expect(attribute_field).to have_value('Attribute Text')

          attribute_field.clear

          expect(find_button('Save ticket')).to have_css('[role="status"][aria-label="Validation failed"]')

          attribute_field.type('New Text')

          expect(find_button('Save ticket')).to have_no_css('[role="status"][aria-label="Validation failed"]')
          expect(ticket[attribute.name]).to eq('Attribute Text')
        end

        submit_form

        ticket.reload
        expect(ticket[attribute.name]).to eq('New Text')
      end
    end
  end

  describe 'Core Workflow' do
    include_examples 'core workflow' do
      let(:object_name) { 'Ticket' }
      let(:form_updater_gql_number) { 1 }
      let(:before_it) do
        lambda {
          visit "/tickets/#{ticket.id}/information"

          wait_for_form_to_settle('form-ticket-edit')
        }
      end
    end
  end
end
