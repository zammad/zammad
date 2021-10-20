# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Objects', type: :system do

  context 'when trying to create invalid attributes' do
    RSpec.shared_examples 'cannot create new object attribute' do |name, error_message|
      context "when trying to create a new attibute '#{name}'" do
        before do
          visit '/#system/object_manager'
          page.find('.js-new').click
        end

        it "fails with '#{error_message}'" do
          within '.modal' do
            fill_in 'name', with: name || 'fallback'
            fill_in 'display', with: 'Not allowed'
            click '.js-submit'
            expect(find('.js-alert')).to have_text(error_message)
          end
        end
      end
    end

    include_examples 'cannot create new object attribute', 'customer_id', 'Object already exists!'
    ['some_other_id', 'some_other_ids', 'some spaces'].each do |name|
      include_examples 'cannot create new object attribute', name, 'are not allowed'
    end
  end

  context 'when creating but then discarding fields again' do
    before do
      visit '/#system/object_manager'
    end

    it 'discards the changes again' do
      page.find('.js-new').click
      within '.modal' do
        fill_in 'name', with: 'new_field'
        fill_in 'display', with: 'New field'
        click '.js-submit'
      end
      click '.js-discard'
      expect(page).to have_no_css('.js-discard')
    end
  end

  context 'when creating and removing a field with migration', db_strategy: :reset do
    RSpec.shared_examples 'create and remove field with migration' do |data_type|
      context "for data_type '#{data_type}'" do
        before do
          visit '/#system/object_manager'
        end

        it 'creates and removes the field correctly' do
          # Create
          page.find('.js-new').click
          within '.modal' do
            fill_in 'name', with: 'new_field'
            fill_in 'display', with: 'New field'
            select data_type, from: 'data_type'
            click '.js-submit'
          end
          expect(page).to have_text('New field')
          expect(page).to have_text('Database Update required')
          click '.js-execute', wait: 7.minutes
          expect(page).to have_text('Zammad need a restart')
          page.refresh

          # Update
          click 'tbody tr:last-child'
          within '.modal' do
            fill_in 'display', with: 'New field updated'
            click '.js-submit'
          end
          expect(page).to have_text('New field updated')
          expect(page).to have_text('Database Update required')
          click '.js-execute', wait: 7.minutes
          expect(page).to have_text('please reload your browser')
          click '.modal-content button.js-submit'

          # Delete
          click 'tbody tr:last-child .js-delete'
          expect(page).to have_text('Database Update required')
          click '.js-execute', wait: 7.minutes
          expect(page).to have_text('Zammad need a restart')
          page.refresh
          expect(page).to have_no_text('New field updated')
        end
      end
    end

    ['Text', 'Select', 'Integer', 'Datetime', 'Date', 'Boolean', 'Tree Select'].each do |data_type|
      include_examples 'create and remove field with migration', data_type
    end
  end

  context 'when creating and modifying tree select fields', db_strategy: :reset do

    let(:object_attribute) do
      attribute = create(:object_manager_attribute_tree_select, name: 'undeletable_field', display: 'Undeletable Field', position: 999)
      ObjectManager::Attribute.migration_execute
      attribute
    end

    it 'creates and updates the fields correctly' do
      # Create the field via API.
      object_attribute
      visit '/#system/object_manager'
      page.refresh
      click 'tbody tr:last-child'

      # Add two new attributes to the field.
      2.times do |i|
        click '.modal tbody tr:last-child .js-addRow'
        find('.modal tbody tr:last-child .js-key').fill_in(with: "new tree option #{i}")
      end
      click '.js-submit'

      expect(page).to have_text('Database Update required')
      click '.js-execute', wait: 7.minutes
      expect(page).to have_text('please reload your browser')
      click '.modal-content button.js-submit'

      # Check that the attributes were correctly saved.
      expect(ObjectManager::Attribute.last.data_option[:options][-2..]).to eq([{ 'name' => 'new tree option 0', 'value' => 'new tree option 0' }, { 'name' => 'new tree option 1', 'value' => 'new tree option 1' }])
    end
  end

  context 'when trying to delete undeletable fields', db_strategy: :reset do
    let(:object_attribute) do
      attribute = create(:object_manager_attribute_text, name: 'undeletable_field', display: 'Undeletable Field', position: 999)
      ObjectManager::Attribute.migration_execute
      attribute
    end

    before do
      create(:overview, condition: {
               "ticket.#{object_attribute.name}" => {
                 operator: 'is',
                 value:    'dummy',
               },
             })
      visit '/#system/object_manager'
    end

    it 'field referenced by an overview is not deletable' do
      expect(page).to have_text(object_attribute.display)
      expect(page).to have_css('tbody tr:last-child span.is-disabled .icon-trash')
    end
  end

  context 'when checking field sorting', db_strategy: :reset do
    # lexicographically ordered list of option strings
    let(:options) { %w[0 000.000 1 100.100 100.200 2 200.100 200.200 3 ä b n ö p sr ß st t ü v] }
    let(:options_hash) { options.reverse.collect { |o| [o, o] }.to_h }

    let(:object_attribute) do
      attribute = create(:object_manager_attribute_select, data_option: { options: options_hash, default: 0 }, position: 999)
      ObjectManager::Attribute.migration_execute
      attribute
    end

    it 'preserves the sorting correctly' do
      object_attribute
      page.refresh
      visit '/#system/object_manager'
      click 'tbody tr:last-child'

      sorted_dialog_values = all('table.settings-list tbody tr td:first-child input').map(&:value).reject { |x| x == '' }
      expect(sorted_dialog_values).to eq(options)

      visit '/#ticket/create'
      sorted_ticket_values = all("select[name=#{object_attribute.name}] option").map(&:value).reject { |x| x == '' }
      expect(sorted_ticket_values).to eq(options)
    end
  end

  context 'when checking selection options removal', db_strategy: :reset do

    let(:options) { %w[äöü cat delete dog ß].index_with { |x| "#{x.capitalize} Display" } }
    let(:options_no_dog) { options.except('dog') }
    let(:options_no_dog_no_delete) { options_no_dog.except('delete') }
    let(:screens) { { 'create_middle' => { 'ticket.agent'=>{ 'shown' => true, 'required' => false, 'item_class' => 'column' } }, 'edit' => { 'ticket.agent'=>{ 'shown' => true, 'required' => false } } } }

    let(:object_attribute) do
      attribute = create(:object_manager_attribute_select, data_option: { options: options, default: 0 }, screens: screens, position: 999)
      ObjectManager::Attribute.migration_execute
      attribute
    end

    it 'handles removed options correctly' do
      object_attribute
      page.refresh

      # Make sure option is present in the first place.
      ticket = create(:ticket, group: Group.find_by(name: 'Users'), object_attribute.name => 'delete')
      visit "/#ticket/zoom/#{ticket.id}"
      sorted_ticket_values = all("select[name=#{object_attribute.name}] option").map(&:value).reject { |x| x == '' }
      expect(sorted_ticket_values).to eq(options.keys)
      expect(find("select[name=#{object_attribute.name}] option:checked").value).to eq('delete')
      expect(find("select[name=#{object_attribute.name}] option:checked").text).to eq('Delete Display')

      # Remove 'delete' and 'dog' options from field via GUI to make sure that the :historical_options attribute is saved.
      visit '/#system/object_manager'
      click 'tbody tr:last-child'
      within '.modal' do
        2.times { find('tr:nth-child(3) .icon-trash').click }
        click '.js-submit'
      end
      expect(page).to have_text('Database Update required')
      click '.js-execute', wait: 7.minutes
      expect(page).to have_text('please reload your browser')
      click '.modal-content button.js-submit'

      # Make sure option is still available in already saved ticket, even though the option was removed from the object attribute.
      # This is done via the :historical_options.
      visit "/#ticket/zoom/#{ticket.id}"

      # Ticket data is loaded from a front end cache first, so wait until there is a consistent state.
      expect(page).to have_css("select[name=#{object_attribute.name}] option[value='delete']")
      expect(page).to have_no_css("select[name=#{object_attribute.name}] option[value='dog']")

      sorted_ticket_values = all("select[name=#{object_attribute.name}] option").map(&:value).reject { |x| x == '' }
      expect(sorted_ticket_values).to eq(options_no_dog.keys)
      expect(find("select[name=#{object_attribute.name}] option:checked").value).to eq('delete')
      expect(find("select[name=#{object_attribute.name}] option:checked").text).to eq('Delete Display')

      # Make sure deleted option is missing for new tickets.
      visit '/#ticket/create'
      sorted_ticket_values = all("select[name=#{object_attribute.name}] option").map(&:value).reject { |x| x == '' }
      expect(sorted_ticket_values).to eq(options_no_dog_no_delete.keys)
    end
  end

  context 'when checking boolean user attributes', db_strategy: :reset do
    let(:organization_object_attribute) do
      attribute = create(:object_manager_attribute_boolean, object_name: 'Organization', data_option: { default: true, options: { true => 'organization:true', false => 'organization:false' } }, screens: screens, position: 999)
      ObjectManager::Attribute.migration_execute
      attribute
    end
    let(:user_object_attribute) do
      attribute = create(:object_manager_attribute_boolean, object_name: 'User', data_option: { default: true, options: { true => 'user:true', false => 'user:false' } }, screens: screens, position: 999)
      ObjectManager::Attribute.migration_execute
      attribute
    end
    let(:organization) { create(:organization, organization_object_attribute.name => false) }
    let(:customer) { create(:customer, user_object_attribute.name => false, organization: organization) }

    let(:screens) { { 'create' => { 'ticket.agent'=>{ 'shown' => true, 'required' => false, 'item_class' => 'column' } }, 'edit' => { 'ticket.agent'=>{ 'shown' => true, 'required' => false } }, 'view' => { 'ticket.agent'=>{ 'shown' => true, 'required' => false } } } }
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), customer: customer) }

    it 'shows user and organization attributes even if they are set to false' do
      organization_object_attribute
      user_object_attribute
      page.refresh
      visit "/#ticket/zoom/#{ticket.id}"
      click('.content.active .tabsSidebar-tab[data-tab="organization"]')
      expect(page).to have_text('organization:false')
      click('.content.active .tabsSidebar-tab[data-tab="customer"]')
      expect(page).to have_text('user:false')
    end
  end

  context 'when creating new fields' do
    before do
      visit '/#system/object_manager'
      page.find('.js-new').click
    end

    it 'verifies option creation order of new tree select options' do
      # set meta information
      fill_in 'Name', with: 'tree1'
      fill_in 'Display', with: 'tree1'
      page.find('select[name=data_type]').select('Tree Select')

      # create 3 childs
      first_add_child = page.first('div.js-addChild')
      first_add_child.click
      first_add_child.click
      first_add_child.click

      # create 1 top level node sibling
      page.first('div.js-addRow').click

      # create 3 childs for the new top level node
      page.all('div.js-addChild').last.click
      page.all('div.js-addChild').last.click
      page.all('div.js-addChild').last.click

      # create new top level nodes by first and second top level node
      add_rows = page.all('div.js-addRow')
      add_rows[0].click
      add_rows[4].click

      # add numbers to all inputs to verify order in config later
      number = 1
      page.all('input.js-key').each do |input|
        input.send_keys(number)
        number += 1
      end

      page.find('.js-submit').click
      expected_data_options = { 'options'    =>
                                                [{ 'name'     => '1',
                                                   'value'    => '1',
                                                   'children' => [{ 'name' => '2', 'value' => '1::2' }, { 'name' => '3', 'value' => '1::3' }, { 'name' => '4', 'value' => '1::4' }] },
                                                 { 'name' => '5', 'value' => '5' },
                                                 { 'name'     => '6',
                                                   'value'    => '6',
                                                   'children' =>
                                                                 [{ 'name'     => '7',
                                                                    'value'    => '6::7',
                                                                    'children' => [{ 'name' => '8', 'value' => '6::7::8', 'children' => [{ 'name' => '9', 'value' => '6::7::8::9' }] }] }] },
                                                 { 'name' => '10', 'value' => '10' }],
                                'default'    => '',
                                'null'       => true,
                                'relation'   => '',
                                'nulloption' => true,
                                'maxlength'  => 255 }

      expect(ObjectManager::Attribute.last.data_option).to eq(expected_data_options)
    end

    it 'checks smart defaults for select field' do
      fill_in 'Name', with: 'select1'
      find('input[name=display]').set('select1')

      page.find('select[name=data_type]').select('Select')

      page.first('div.js-add').click
      page.first('div.js-add').click
      page.first('div.js-add').click

      counter = 0
      page.all('.js-key').each do |field|
        field.set(counter)
        counter += 1
      end

      page.all('.js-value')[-2].set('special 2')
      page.find('.js-submit').click

      expected_data_options = {
        '0' => '0',
        '1' => '1',
        '2' => 'special 2',
      }

      expect(ObjectManager::Attribute.last.data_option['options']).to eq(expected_data_options)
    end

    it 'checks smart defaults for boolean field' do
      fill_in 'Name', with: 'bool1'
      find('input[name=display]').set('bool1')

      page.find('select[name=data_type]').select('Boolean')
      page.find('.js-valueFalse').set('HELL NOO')
      page.find('.js-submit').click

      expected_data_options = {
        true  => 'yes',
        false => 'HELL NOO',
      }

      expect(ObjectManager::Attribute.last.data_option['options']).to eq(expected_data_options)
    end

    it 'checks default boolean value visibility' do
      fill_in 'Name', with: 'bool1'
      find('input[name=display]').set('Bool 1')

      page.find('select[name=data_type]').select('Boolean')
      choose('data_option::default', option: 'true')
      page.find('.js-submit').click

      td = page.find(:css, 'td', text: 'bool1')
      tr = td.find(:xpath, './parent::tr')

      tr.click

      expect(page).to have_checked_field('data_option::default', with: 'true')
    end
  end

  # https://github.com/zammad/zammad/issues/3647
  context 'when setting Min/Max values for integer' do
    before do
      visit '/#system/object_manager'
      page.find('.js-new').click

      in_modal disappears: false do
        fill_in 'Name', with: 'integer1'
        fill_in 'Display', with: 'Integer1'
        page.find('select[name=data_type]').select('Integer')
      end
    end

    it 'verifies max value does not go above limit' do
      in_modal disappears: false do
        fill_in 'Maximal', with: '999999999999'

        page.find('.js-submit').click

        expect(page).to have_text 'Data option max must be lower than 2147483648'
      end
    end

    it 'verifies max value does not go below limit' do
      in_modal disappears: false do
        fill_in 'Maximal', with: '-999999999999'

        page.find('.js-submit').click

        expect(page).to have_text 'Data option max must be higher than -2147483648'
      end
    end

    it 'verifies max value can be set' do
      in_modal do
        fill_in 'Maximal', with: '128'

        page.find('.js-submit').click
      end

      expect(page).to have_text 'Integer1'
    end

    it 'verifies max value can be set to a negative value' do
      in_modal do
        fill_in 'Minimal', with: '-256'
        fill_in 'Maximal', with: '-128'

        page.find('.js-submit').click
      end

      expect(page).to have_text 'Integer1'
    end

    it 'verifies min value does not go above limit' do
      in_modal disappears: false do
        fill_in 'Minimal', with: '999999999999'

        page.find('.js-submit').click

        expect(page).to have_text 'Data option min must be lower than 2147483648'
      end
    end

    it 'verifies min value does not go below limit' do
      in_modal disappears: false do
        fill_in 'Minimal', with: '-999999999999'

        page.find('.js-submit').click

        expect(page).to have_text 'Data option min must be higher than -2147483648'
      end
    end

    it 'verifies min value can be set' do
      in_modal do
        fill_in 'Minimal', with: '128'

        page.find('.js-submit').click
      end

      expect(page).to have_text 'Integer1'
    end

    it 'verifies min value can be set to a negative value' do
      in_modal do
        fill_in 'Minimal', with: '-128'

        page.find('.js-submit').click
      end

      expect(page).to have_text 'Integer1'
    end

    it 'verifies min value must be lower than max' do
      in_modal disappears: false do
        fill_in 'Minimal', with: '128'
        fill_in 'Maximal', with: '-128'

        page.find('.js-submit').click

        expect(page).to have_text 'Data option min must be lower than max'
      end
    end
  end

  context 'when creating with no diff' do
    before do
      visit '/#system/object_manager'
      page.find('.js-new').click

      in_modal disappears: false do
        fill_in 'Name', with: 'nodiff'
        fill_in 'Display', with: 'NoDiff'
      end
    end

    it 'date attribute' do
      page.find('select[name=data_type]').select('Date')
      fill_in 'Default time Diff (hours)', with: ''

      expect { page.find('.js-submit').click }.to change(ObjectManager::Attribute, :count).by(1)
    end

    it 'datetime attribute' do
      page.find('select[name=data_type]').select('Datetime')
      fill_in 'Default time Diff (minutes)', with: ''

      expect { page.find('.js-submit').click }.to change(ObjectManager::Attribute, :count).by(1)
    end
  end
end
