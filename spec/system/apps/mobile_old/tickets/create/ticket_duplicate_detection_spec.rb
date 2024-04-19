# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Assist agent/customer to prevent duplicate ticket creation #4592', app: :mobile, authenticated_as: :authenticate, type: :system do
  let(:permitted_group1)    { create(:group) }
  let(:permitted_group2)    { create(:group) }
  let(:non_permitted_group) { create(:group) }
  let(:current_user)        { create(:agent, groups: [permitted_group1, permitted_group2]) }
  let(:customer)            { create(:customer) }
  let(:ticket1)             { create(:ticket, customer: customer, group: permitted_group1, title: '123') }
  let(:ticket2)             { create(:ticket, customer: customer, group: permitted_group2, title: 'ABC') }
  let(:ticket3)             { create(:ticket, group: non_permitted_group, title: '123') }
  let(:ticket4)             { create(:ticket, group: non_permitted_group, title: 'XXX') }
  let(:attributes)          { %w[group_id title] }
  let(:show_tickets)        { true }
  let(:permission_level)    { 'user' }
  let(:role_ids)            { [Role.find_by(name: 'Agent').id] }

  def authenticate
    create_text_attribute if defined?(create_text_attribute)

    ticket1 && ticket2 && ticket3 && ticket4

    Setting.set('ticket_duplicate_detection', true)
    Setting.set('ticket_duplicate_detection_attributes', attributes)
    Setting.set('ticket_duplicate_detection_show_tickets', show_tickets)
    Setting.set('ticket_duplicate_detection_permission_level', permission_level)
    Setting.set('ticket_duplicate_detection_role_ids', role_ids)

    current_user
  end

  def next_step
    find_button('Continue').click
  end

  before do
    visit '/tickets/create'

    wait_for_form_to_settle('ticket-create')
  end

  shared_examples 'showing a warning' do
    it 'shows a warning' do
      within_form(form_updater_gql_number: 1) do

        # Step 1.
        find_input('Title').type(title) if defined?(title)
        next_step if defined?(test_group) || defined?(text_attribute)

        # Step 2.
        next_step if current_user != customer && (defined?(test_group) || defined?(text_attribute))

        # Step 3.
        find_select('Group').select_option(test_group.name) if defined?(test_group)
        find_input('Text Attribute').type(text_attribute) if defined?(text_attribute)
      end

      expect(page).to have_text 'Similar tickets found'
      expect(page).to have_text 'Tickets with the same attributes were found.'

      shown_tickets.each do |ticket|
        expect(page).to have_text ticket.number
      end

      hidden_tickets.each do |ticket|
        expect(page).to have_no_text ticket.number
      end
    end
  end

  shared_examples 'showing no warning' do
    it 'shows no warning' do
      within_form(form_updater_gql_number: 1) do

        # Step 1.
        find_input('Title').type(title) if defined?(title)
        next_step if defined?(test_group)

        # Step 2.
        next_step if defined?(test_group)

        # Step 3.
        find_select('Group').select_option(test_group.name) if defined?(test_group)
      end

      expect(page).to have_no_text 'Similar tickets found'
    end
  end

  context 'with matching attributes shows a warning and accessible tickets only' do
    let(:title)          { '123' }
    let(:test_group)     { permitted_group1 }
    let(:shown_tickets)  { [ticket1] }
    let(:hidden_tickets) { [ticket2, ticket3, ticket4] }

    it_behaves_like 'showing a warning'
  end

  context 'with non-matching attributes shows no warning' do
    let(:title) { '123' }
    let(:test_group) { permitted_group2 }

    it_behaves_like 'showing no warning'
  end

  context 'with matching attributes but no access to the tickets shows no warning' do
    let(:title) { 'XXX' }
    let(:test_group) { permitted_group1 }

    it_behaves_like 'showing no warning'
  end

  context 'with no tickets shown in the warning' do
    let(:show_tickets) { false }

    context 'with matching attributes shows a warning without tickets' do
      let(:title)               { '123' }
      let(:test_group)          { permitted_group1 }
      let(:shown_tickets)       { [] }
      let(:hidden_tickets)      { [ticket1, ticket2, ticket3, ticket4] }

      it_behaves_like 'showing a warning'
    end
  end

  context 'with permission level system' do
    let(:attributes)       { ['title'] }
    let(:permission_level) { 'system' }

    context 'with matching attributes shows a warning and accessible tickets only' do
      let(:title)          { '123' }
      let(:shown_tickets)  { [ticket1] }
      let(:hidden_tickets) { [ticket2, ticket3, ticket4] }

      it_behaves_like 'showing a warning'
    end
  end

  context 'with permission level user' do
    let(:attributes) { ['title'] }

    context 'with matching attributes shows a warning and accessible tickets only' do
      let(:title)          { '123' }
      let(:shown_tickets)  { [ticket1] }
      let(:hidden_tickets) { [ticket2, ticket3, ticket4] }

      it_behaves_like 'showing a warning'
    end
  end

  context 'with customer user' do
    let(:current_user) { customer }
    let(:role_ids)     { [Role.find_by(name: 'Customer').id] }

    context 'with matching attributes shows a warning and accessible tickets only' do
      let(:title)          { '123' }
      let(:test_group)     { permitted_group1 }
      let(:shown_tickets)  { [ticket1] }
      let(:hidden_tickets) { [ticket2, ticket3, ticket4] }

      it_behaves_like 'showing a warning'
    end
  end

  context 'with custom object attribute', db_strategy: :reset do
    let(:attributes) { ['text_attribute'] }
    let(:ticket1)    { create(:ticket, customer: customer, group: permitted_group1, title: '123', text_attribute: text_attribute) }
    let(:ticket2)    { create(:ticket, customer: customer, group: permitted_group2, title: 'ABC', text_attribute: 'baz qux') }
    let(:ticket3)    { create(:ticket, group: non_permitted_group, title: '123', text_attribute: text_attribute) }
    let(:ticket4)    { create(:ticket, group: non_permitted_group, title: '123', text_attribute: text_attribute) }

    def create_text_attribute
      create(:object_manager_attribute_text, :required_screen, name: 'text_attribute', display: 'Text Attribute', data_option: {
               'type'      => 'text',
               'maxlength' => 255,
               'null'      => true,
               'translate' => false,
               'default'   => '',
               'options'   => {},
               'relation'  => '',
             })
      ObjectManager::Attribute.migration_execute
    end

    context 'with matching attributes shows a warning and accessible tickets only' do
      let(:text_attribute) { 'foobar' }
      let(:shown_tickets)  { [ticket1] }
      let(:hidden_tickets) { [ticket2, ticket3, ticket4] }

      it_behaves_like 'showing a warning'
    end
  end
end
