# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile/examples/core_workflow_examples'

RSpec.describe 'Mobile > Ticket > Create', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)     { Group.find_by(name: 'Users') }
  let(:agent)     { create(:agent, groups: [group]) }
  let!(:customer) { create(:customer) }

  def next_step
    find_button('Continue').click
  end

  def check_is_step(step)
    expect(find("button[order=\"#{step}\"]").disabled?).to be(true)
  end

  def go_to_step(step)
    find("button[order=\"#{step}\"]").click
  end

  def submit_form
    find_button('Create ticket', match: :first).click
    wait_for_gql('apps/mobile/pages/ticket/graphql/mutations/create.graphql')
  end

  def check_is_focused(element)
    expect(page.driver.browser.switch_to.active_element).to eql(element.native)
  end

  before do
    visit '/tickets/create'
    wait_for_form_to_settle('ticket-create')
  end

  shared_examples 'creating a ticket' do |article_type:, direction: nil|
    it 'can complete all steps' do
      expect(find_button('Create ticket', match: :first, disabled: true).disabled?).to be(true)

      within_form(form_updater_gql_number: 1) do

        # Step 1.
        find_input('Title').type(Faker::Name.name_with_middle)
        next_step

        # Step 2.
        case article_type
        when 'email'
          find_radio('articleSenderType').select_choice('Send Email')
        when 'phone'
          if direction == 'out'
            find_radio('articleSenderType').select_choice('Outbound Call')
          end
        end
        next_step

        # Step 3.
        find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
        find_autocomplete('CC') if article_type == 'email'
        next_step

        # Step 4.
        find_editor('Text').type(Faker::Hacker.say_something_smart)
      end

      submit_form

      find('[role=alert]', text: 'Ticket has been created successfully.')

      expect(page).to have_current_path("/mobile/tickets/#{Ticket.last.id}")
      expect(Ticket.last.create_article_type_id).to eq(Ticket::Article::Type.find_by(name: article_type).id)
    end
  end

  context 'with different article types' do
    it_behaves_like 'creating a ticket', article_type: 'phone'
    it_behaves_like 'creating a ticket', article_type: 'phone', direction: 'out'
    it_behaves_like 'creating a ticket', article_type: 'email'
  end

  context 'with signatures' do
    let(:signature1) { create(:signature, body: '<strong>custom signature</strong>') }
    let(:group1)     { create(:group, signature: signature1) }
    let(:group2)     { Group.find_by(name: 'Users') }
    let(:group3)     { create(:group) }
    let(:agent)      { create(:agent, groups: [group1, group2, group3]) }

    it 'adds signature' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.name_with_middle)
        next_step

        find_radio('articleSenderType').select_choice('Send Email')

        next_step
        next_step

        # only label is rendered as text
        expect(find_editor('Text')).to have_text_value('', exact: true)

        go_to_step(3)
        find_select('Group').select_option('Users')

        go_to_step(4)
        expect(find_editor('Text')).to have_text_value(agent.fullname) # default signature is added
      end
    end

    it 'changes signature, when group is changed' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.name_with_middle)
        next_step

        find_radio('articleSenderType').select_choice('Send Email')
        next_step

        find_select('Group').select_option('Users')
        next_step

        expect(find_editor('Text')).to have_text_value(agent.fullname)

        go_to_step(3)
        find_select('Group').select_option(group1.name)

        next_step
        expect(find_editor('Text')).to have_text_value('custom signature')
      end
    end

    it 'removes signature, when another group without signature is selected' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.name_with_middle)
        next_step

        find_radio('articleSenderType').select_choice('Send Email')
        next_step

        find_select('Group').select_option('Users')
        next_step

        expect(find_editor('Text')).to have_text_value(agent.fullname)

        go_to_step(3)
        find_select('Group').select_option(group3.name)

        next_step
        expect(find_editor('Text')).to have_text_value('', exact: true)
      end
    end

    it 'removes signature when type is not email' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.name_with_middle)
        next_step

        find_radio('articleSenderType').select_choice('Send Email')
        next_step

        find_select('Group').select_option('Users')
        next_step

        expect(find_editor('Text')).to have_text_value(agent.fullname)

        go_to_step(2)
        find_radio('articleSenderType').select_choice('Outbound Call')

        go_to_step(4)

        # only label is rendered as text
        expect(find_editor('Text')).to have_text_value('', exact: true)
      end
    end
  end

  context 'with entered form fields' do
    it 'remembers the data when switching between steps' do

      within_form(form_updater_gql_number: 1) do

        # Step 1.
        title = Faker::Name.name_with_middle
        find_input('Title').type(title)
        next_step

        # Step 2.
        type = 'Outbound Call'
        find_radio('articleSenderType').select_choice(type)
        next_step

        # Step 3.
        find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
        next_step

        # Step 4.
        body = Faker::Hacker.say_something_smart
        find_editor('Text').type(body)

        # Step 1.
        go_to_step(1)
        expect(find_input('Title')).to have_value(title)

        # Step 3.
        go_to_step(3)
        expect(find_autocomplete('Customer')).to have_selected_option(customer.fullname)

        # Step 2.
        go_to_step(2)
        expect(find_radio('articleSenderType')).to have_selected_choice(type)

        # Step 4.
        go_to_step(4)
        expect(find_editor('Text')).to have_text_value(body)
      end
    end

    it 'shows a confirmation dialog when leaving the screen' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.name_with_middle)
      end

      find('button[aria-label="Go back"]').click

      within '[role=alert]' do
        expect(page).to have_text('Are you sure? You have unsaved changes that will get lost.')
      end
    end
  end

  context 'with accessibility support' do
    it 'focuses first visible field when switching between steps' do

      # Step 1.
      check_is_focused find_input('Title').input_element
      next_step

      # Step 2.
      check_is_focused find_radio('articleSenderType').find('label', text: 'Received Call').find('input')
      next_step

      # Step 3.
      check_is_focused find_autocomplete('Customer').input_element
      next_step

      # Step 4.
      check_is_focused find_editor('Text').input_element

      # Step 1.
      go_to_step(1)
      check_is_focused find_input('Title').input_element

      # Step 3.
      go_to_step(3)
      check_is_focused find_autocomplete('Customer').input_element

      # Step 2.
      go_to_step(2)
      check_is_focused find_radio('articleSenderType').find('label', text: 'Received Call').find('input')

      # Step 4.
      go_to_step(4)
      check_is_focused find_editor('Text').input_element
    end

    it 'advances to the next step on submit' do
      find_input('Title').input_element.send_keys :enter
      check_is_step(2)

      find_radio('articleSenderType').find('label', text: 'Received Call').find('input').send_keys :enter
      check_is_step(3)
    end
  end

  describe 'Core Workflow' do
    include_examples 'core workflow' do
      let(:object_name) { 'Ticket' }
      let(:form_updater_gql_number) { 2 }
      let(:before_it) do
        lambda {
          visit '/tickets/create'
          wait_for_form_to_settle('ticket-create')

          within_form(form_updater_gql_number: 1) do
            find_input('Title').type(Faker::Name.name_with_middle)
          end

          next_step
          next_step
        }
      end
    end
  end
end
