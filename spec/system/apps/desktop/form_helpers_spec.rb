# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Form helpers', app: :desktop_view, authenticated_as: :agent, db_strategy: :reset, time_zone: 'Europe/London', type: :system do
  let(:group)       { Group.find_by(name: 'Users') }
  let(:agent)       { create(:agent, groups: [group]) }
  let(:object_name) { 'Ticket' }
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

  before do
    visit '/tickets/create'
    wait_for_form_to_settle('ticket-create')
  end

  context 'with single select field', authenticated_as: :authenticate do
    def authenticate
      create(:object_manager_attribute_select, object_name: object_name, name: 'single_select', display: 'Single Select', screens: screens, additional_data_options: { options: { '1' => 'Option 1', '2' => 'Option 2', '3' => 'Option 3' } })

      ObjectManager::Attribute.migration_execute
      agent
    end

    it 'provides test helpers' do
      el = find_select('Single Select')
      el.select_option('Option 1')
      expect(el).to have_selected_option('Option 1')
      el.clear_selection
      expect(el).to have_no_selected_option('Option 1')
    end
  end

  context 'with multi select field', authenticated_as: :authenticate do
    def authenticate
      create(:object_manager_attribute_multiselect, object_name: object_name, name: 'multi_select', display: 'Multi Select', screens: screens, additional_data_options: { options: { '1' => 'Option 1', '2' => 'Option 2', '3' => 'Option 3' } })

      ObjectManager::Attribute.migration_execute
      agent
    end

    it 'provides test helpers' do
      el = find_select('Multi Select')
      el.select_options(['Option 1', 'Option 2'])
      expect(el).to have_selected_options(['Option 1', 'Option 2'])
      el.clear_selection
      expect(el).to have_no_selected_options(['Option 1', 'Option 2'])
    end
  end

  context 'with tree select field', authenticated_as: :authenticate do
    let(:data_options) do
      {
        'options'    => [
          {
            'name'     => 'Parent 1',
            'value'    => '1',
            'children' => [
              {
                'name'  => 'Option A',
                'value' => '1::a',
              },
              {
                'name'  => 'Option B',
                'value' => '1::b',
              },
            ],
          },
          {
            'name'     => 'Parent 2',
            'value'    => '2',
            'children' => [
              {
                'name'  => 'Option C',
                'value' => '2::c'
              },
            ],
          },
          {
            'name'  => 'Option 3',
            'value' => '3'
          },
        ],
        'default'    => '',
        'null'       => true,
        'relation'   => '',
        'maxlength'  => 255,
        'nulloption' => true,
      }
    end

    def authenticate
      create(:object_manager_attribute_tree_select, object_name: object_name, name: 'tree_select', display: 'Tree Select', screens: screens, additional_data_options: data_options)

      ObjectManager::Attribute.migration_execute
      agent
    end

    it 'provides test helpers' do
      el = find_treeselect('Tree Select')
      el.select_option('Parent 1::Option A')
      expect(el).to have_selected_option_with_parent('Parent 1::Option A')
      el.clear_selection
      expect(el).to have_no_selected_option_with_parent('Parent 1::Option A')
      el.search_for_option('Parent 2::Option C')
      expect(el).to have_selected_option_with_parent('Parent 2::Option C')
      el.clear_selection.search_for_option('Option C') # chained
      expect(el).to have_selected_option_with_parent('Parent 2::Option C')
    end
  end

  context 'with multi tree select field', authenticated_as: :authenticate do
    let(:data_options) do
      {
        'options'    => [
          {
            'name'     => 'Parent 1',
            'value'    => '1',
            'children' => [
              {
                'name'  => 'Option A',
                'value' => '1::a',
              },
              {
                'name'  => 'Option B',
                'value' => '1::b',
              },
            ],
          },
          {
            'name'     => 'Parent 2',
            'value'    => '2',
            'children' => [
              {
                'name'  => 'Option C',
                'value' => '2::c'
              },
            ],
          },
          {
            'name'  => 'Option 3',
            'value' => '3'
          },
        ],
        'default'    => '',
        'null'       => true,
        'relation'   => '',
        'maxlength'  => 255,
        'nulloption' => true,
      }
    end

    def authenticate
      create(:object_manager_attribute_multi_tree_select, object_name: object_name, name: 'tree_select', display: 'Multi Tree Select', screens: screens, additional_data_options: data_options)

      ObjectManager::Attribute.migration_execute
      agent
    end

    it 'provides test helpers' do
      el = find_treeselect('Multi Tree Select')
      el.select_options(['Parent 1::Option A', 'Parent 2::Option C'])
      expect(el).to have_selected_options_with_parent(['Parent 1::Option A', 'Parent 2::Option C'])
      el.clear_selection
      expect(el).to have_no_selected_options_with_parent(['Parent 1::Option A', 'Parent 2::Option C'])
    end
  end

  context 'with customer and organization fields' do
    let(:organization)            { create(:organization) }
    let(:secondary_organizations) { create_list(:organization, 5) }
    let!(:customer)               { create(:customer, organization_id: organization.id, organization_ids: secondary_organizations.map(&:id)) }

    it 'provides test helpers' do
      el = find_autocomplete('Customer')
      el.search_for_option(customer.email, label: customer.fullname) # search for fullname does not work without ES
      expect(el).to have_selected_option(customer.fullname)

      el = find_autocomplete('Organization')
      el.select_option(secondary_organizations.last.name)
      expect(el).to have_selected_option(secondary_organizations.last.name)
    end
  end

  context 'with recipient field' do
    let(:email_address_1) { Faker::Internet.unique.email }
    let(:email_address_2) { Faker::Internet.unique.email }

    before do
      find('[role="tab"]', text: 'Send Email').click
    end

    it 'provides test helpers' do
      within_form(form_updater_gql_number: 2) do
        el = find_autocomplete('CC')
        el.search_for_options([email_address_1, email_address_2], use_action: true)
        expect(el).to have_selected_options([email_address_1, email_address_2])
      end
    end
  end

  context 'with tags field', authenticated_as: :authenticate do
    let(:tag_1) { Faker::Hacker.unique.noun }
    let(:tag_2) { Faker::Hacker.unique.noun }
    let(:tag_3) { Faker::Hacker.unique.noun }
    let(:tags) do
      [
        Tag::Item.lookup_by_name_and_create('foo'),
      ]
    end

    def authenticate
      tags
      agent
    end

    it 'provides test helpers' do
      within_form(form_updater_gql_number: 1) do
        el = find_autocomplete('Tags')
        el.select_option('foo').search_for_options([tag_1, tag_2, tag_3])
        expect(el).to have_selected_options(['foo', tag_1, tag_2, tag_3])
      end
    end
  end

  context 'with editor field' do
    let(:body) { Faker::Hacker.say_something_smart }

    it 'provides test helpers' do
      within_form(form_updater_gql_number: 1) do
        el = find_editor('Text')
        el.type(body)
        expect(el).to have_data_value(body)
        el.clear
        expect(el).to have_no_data_value(body)
      end
    end
  end

  context 'with date and datetime fields', authenticated_as: :authenticate do
    let(:date)     { Date.parse('2022-09-07') }
    let(:datetime) { DateTime.parse('2023-09-07T12:00:00.000Z') }

    def authenticate
      create(:object_manager_attribute_date, object_name: object_name, name: 'date', display: 'Date', screens: screens)
      create(:object_manager_attribute_datetime, object_name: object_name, name: 'datetime', display: 'Date Time', screens: screens)

      ObjectManager::Attribute.migration_execute
      agent
    end

    it 'provides test helpers' do
      el = find_datepicker(nil, exact_text: 'Date')
      el.select_date(date)
      expect(el).to have_date(date)
      el.clear
      expect(el).to have_no_date(date)
      el.type_date(date)
      expect(el).to have_date(date)

      el = find_datepicker('Date Time')
      el.select_datetime(datetime)
      expect(el).to have_datetime(datetime)
      el.clear
      expect(el).to have_no_datetime(datetime)
      el.type_datetime(datetime)
      expect(el).to have_datetime(datetime)
    end
  end

  context 'with boolean field', authenticated_as: :authenticate do
    def authenticate
      create(:object_manager_attribute_boolean, object_name: object_name, name: 'boolean', display: 'Boolean', screens: screens)

      ObjectManager::Attribute.migration_execute
      agent
    end

    it 'provides test helpers' do
      el = find_toggle('Boolean')
      el.toggle
      expect(el).to be_toggled_on
      el.toggle_off
      expect(el).to be_toggled_off
      el.toggle_on
      expect(el).to be_toggled_on
    end
  end
end
