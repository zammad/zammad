# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile_old/examples/core_workflow_examples'

RSpec.describe 'Mobile > Ticket > Create', app: :mobile, authenticated_as: :user, type: :system do
  let(:group)     { Group.find_by(name: 'Users') }
  let(:user)      { create(:agent, groups: [group]) }
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
    find_button('Create').click
    wait_for_gql('shared/entities/ticket/graphql/mutations/create.graphql')
  end

  def check_is_focused(element)
    wait.until do
      page.driver.browser.switch_to.active_element == element.native
    end
  end

  before do
    visit '/tickets/create'
    wait_for_form_to_settle('ticket-create')
  end

  shared_examples 'creating a ticket' do |article_type:, direction: nil, redirect: nil|
    it 'can complete all steps' do
      expect(find_button('Create', disabled: true).disabled?).to be(true)

      within_form(form_updater_gql_number: 1) do

        # Step 1.
        find_input('Title').type(Faker::Name.unique.name_with_middle)
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

        find_select('Group').select_option('Users') if article_type == 'web'

        next_step

        if article_type != 'web'
          # Step 3.
          find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
          find_autocomplete('CC') if article_type == 'email'
          next_step
        end

        # Step 4.
        find_editor('Text').type(Faker::Hacker.say_something_smart)
      end

      submit_form

      find('[role=alert]', text: 'Ticket has been created successfully.')

      expect(page).to have_current_path(redirect || "/mobile/tickets/#{Ticket.last.id}")
      expect(Ticket.last.create_article_type_id).to eq(Ticket::Article::Type.find_by(name: article_type).id)
    end
  end

  context 'with different article types' do
    it_behaves_like 'creating a ticket', article_type: 'phone'
    it_behaves_like 'creating a ticket', article_type: 'phone', direction: 'out'
    it_behaves_like 'creating a ticket', article_type: 'email'

    context 'when dont have a "read" permission, but have "create" permission' do
      it_behaves_like 'creating a ticket', article_type: 'email', redirect: '/mobile/' do
        before do
          user.group_names_access_map = {
            group.name => ['create']
          }
        end
      end
    end

    context 'when a customer', authenticated_as: :customer do
      it_behaves_like 'creating a ticket', article_type: 'web'
    end
  end

  context 'with signatures' do
    let(:signature1) { create(:signature, body: '<strong>custom signature</strong>') }
    let(:group1)     { create(:group, signature: signature1) }
    let(:group2)     { Group.find_by(name: 'Users') }
    let(:group3)     { create(:group) }
    let(:user)       { create(:agent, groups: [group1, group2, group3]) }

    it 'adds signature' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.unique.name_with_middle)
        next_step

        find_radio('articleSenderType').select_choice('Send Email')

        next_step
        next_step

        # only label is rendered as text
        expect(find_editor('Text')).to have_text_value('', exact: true)

        go_to_step(3)
        find_select('Group').select_option('Users')

        go_to_step(4)
        expect(find_editor('Text')).to have_text_value(user.fullname) # default signature is added
      end
    end

    it 'changes signature, when group is changed' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.unique.name_with_middle)
        next_step

        find_radio('articleSenderType').select_choice('Send Email')
        next_step

        find_select('Group').select_option('Users')
        next_step

        expect(find_editor('Text')).to have_text_value(user.fullname)

        go_to_step(3)
        find_select('Group').select_option(group1.name)

        next_step
        expect(find_editor('Text')).to have_text_value('custom signature')
      end
    end

    it 'removes signature, when another group without signature is selected' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.unique.name_with_middle)
        next_step

        find_radio('articleSenderType').select_choice('Send Email')
        next_step

        find_select('Group').select_option('Users')
        next_step

        expect(find_editor('Text')).to have_text_value(user.fullname)

        go_to_step(3)
        find_select('Group').select_option(group3.name)

        next_step
        expect(find_editor('Text')).to have_text_value('', exact: true)
      end
    end

    it 'removes signature when type is not email' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.unique.name_with_middle)
        next_step

        find_radio('articleSenderType').select_choice('Send Email')
        next_step

        find_select('Group').select_option('Users')
        next_step

        expect(find_editor('Text')).to have_text_value(user.fullname)

        go_to_step(2)
        find_radio('articleSenderType').select_choice('Outbound Call')

        go_to_step(4)

        # only label is rendered as text
        expect(find_editor('Text')).to have_text_value('', exact: true)
      end
    end

    it 'removes signature when group is deselected' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.unique.name_with_middle)
        next_step

        find_radio('articleSenderType').select_choice('Send Email')
        next_step

        find_select('Group').select_option('Users')
        next_step

        expect(find_editor('Text')).to have_text_value(user.fullname)

        go_to_step(3)
        find_select('Group').clear_selection

        go_to_step(4)

        # only label is rendered as text
        expect(find_editor('Text')).to have_text_value('', exact: true)
      end
    end
  end

  # TODO: Frontend tests!?
  context 'with entered form fields' do
    it 'remembers the data when switching between steps' do

      within_form(form_updater_gql_number: 1) do

        # Step 1.
        title = Faker::Name.unique.name_with_middle
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
        find_input('Title').type(Faker::Name.unique.name_with_middle)
      end

      find_button('Go home').click

      within '[role=alert]' do
        expect(page).to have_text('Are you sure? You have unsaved changes that will get lost.')
      end
    end

    it 'fills out new customer when it\'s created in place' do

      within_form(form_updater_gql_number: 1) do

        find_input('Title').type(Faker::Name.unique.name_with_middle)
        next_step
        next_step

        find_autocomplete('Customer').element.click
        find_button('Create new customer').click

        find_input('First name').type('John')
        find_input('Last name').type('Doe')

        click_on('Save')

        expect(find_autocomplete('Customer')).to have_selected_option('John Doe')
      end
    end
  end

  context 'with accessibility support' do
    it 'focuses first visible field when switching between steps' do
      wait_for_form_autofocus('ticket-create')

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

    context 'with many object attributes', authenticated_as: :authenticate, db_strategy: :reset do
      let(:screens) do
        {
          create_middle: {
            '-all-' => {
              shown:    true,
              required: false,
            },
          },
        }
      end

      def authenticate
        create(:object_manager_attribute_select, screens: screens)
        create(:object_manager_attribute_text, screens: screens)
        create(:object_manager_attribute_tree_select, screens: screens)
        create(:object_manager_attribute_select, screens: screens)

        ObjectManager::Attribute.migration_execute

        true
      end

      it 'can interact with the fields at the bottom of the form without any obstructions' do

        # Step 3.
        next_step
        next_step

        # Tags is the last field in the form.
        #   In case the field is obscured, the following action would fail.
        find_autocomplete('Tags').search_for_option('tag 1')
      end
    end
  end

  context 'when using ticket create as customer' do
    let(:group1) { Group.find_by(name: 'Users') }
    let(:user)   { create(:customer, :with_org, groups: [group1]) }

    shared_examples 'can complete all steps as customer' do
      it 'can complete all steps' do
        within_form(form_updater_gql_number: 1) do
          find_input('Title').type(Faker::Name.unique.name_with_middle)
          next_step

          find_select('Group').select_option('Users')

          if organizations
            find_select('Organization').select_option(organizations.last.name)
          else
            expect(page).to have_no_select('Organization')
          end

          next_step

          find_editor('Text').type(Faker::Hacker.say_something_smart)
        end

        submit_form

        find('[role=alert]', text: 'Ticket has been created successfully.')

        expect(page).to have_current_path("/mobile/tickets/#{Ticket.last.id}")
      end
    end

    context 'with secondary organizations' do
      include_examples 'can complete all steps as customer' do
        let(:user)          { create(:customer, :with_org, organizations: organizations, groups: [group1]) }
        let(:organizations) { create_list(:organization, 3) }
      end
    end

    context 'without secondary organizations' do
      include_examples 'can complete all steps as customer' do
        let(:organizations) { nil }
      end
    end
  end

  context 'when using suggestions' do
    let(:text_option) { create(:text_module, name: 'test', content: "Hello, \#{ticket.customer.firstname}!") }

    it 'text suggestion parses correctly' do
      within_form(form_updater_gql_number: 1) do
        find_input('Title').type(Faker::Name.unique.name_with_middle)
        next_step
        next_step

        find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
        next_step

        editor = find_editor('Text')
        # only label is rendered as text
        expect(editor).to have_text_value('', exact: true)

        editor.type('::test')
        find('[role="option"]', text: text_option.name).click

        expect(editor).to have_text_value("Hello, #{customer.firstname}!")
      end
    end
  end

  describe 'Core Workflow' do
    include_examples 'mobile app: core workflow' do
      let(:object_name)             { 'Ticket' }
      let(:form_updater_gql_number) { 2 }
      let(:before_it) do
        lambda {
          visit '/tickets/create'
          wait_for_form_to_settle('ticket-create')

          within_form(form_updater_gql_number: 1) do
            find_input('Title').type(Faker::Name.unique.name_with_middle)
          end

          next_step
          next_step
        }
      end
    end
  end
end
