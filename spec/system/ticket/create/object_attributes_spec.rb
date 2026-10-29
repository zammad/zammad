# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Create > Object attributes', time_zone: 'Europe/London', type: :system do
  describe 'object manager attributes maxlength', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_text, :required_screen, name: 'maxtest', display: 'maxtest', data_option: {
               'type'      => 'text',
               'maxlength' => 3,
               'null'      => true,
               'translate' => false,
               'default'   => '',
               'options'   => {},
               'relation'  => '',
             })
      ObjectManager::Attribute.migration_execute
      true
    end

    it 'checks ticket create' do
      visit 'ticket/create'
      within(:active_content) do
        fill_in 'maxtest', with: 'hellu'
        expect(page).to have_field('maxtest', with: 'hel')
      end
    end
  end

  describe 'object manager attributes default date', authenticated_as: :authenticate, db_strategy: :reset do
    let(:template)   { create(:template, :dummy_data) }
    let(:field_date) { find 'input[name="{date}date_test"]', visible: :all }
    let(:field_time) { find 'input[name="{datetime}datetime_test"]', visible: :all }

    def authenticate
      template

      screens = {
        'create_top' => {
          '-all-' => {
            'null' => true
          }
        },
      }

      create(:object_manager_attribute_date, name: 'date_test', display: 'date_test', default: 24, screens: screens)
      create(:object_manager_attribute_datetime, name: 'datetime_test', display: 'datetime_test', default: 100, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    before do
      visit '/'

      travel 1.month
      browser_travel_to Time.current

      visit 'ticket/create'
      use_template template, without_taskbar: true
    end

    it 'prefills date' do
      expect(field_date.value).to eq 1.day.from_now.to_date.to_s
    end

    it 'prefills datetime' do
      expect(Time.zone.parse(field_time.value)).to eq 100.minutes.from_now.change(sec: 0, usec: 0)
    end

    it 'saves dates' do
      click '.js-submit'

      date = 1.day.from_now.to_date
      time = 100.minutes.from_now.change(sec: 0)

      expect(Ticket.last).to have_attributes date_test: date, datetime_test: time
    end

    it 'allows to save with different values' do
      date = 2.days.from_now.to_date
      time = 200.minutes.from_now.change(sec: 0)

      field_date.sibling('[data-item=date]').set date.strftime('%m/%d/%Y')
      field_time.sibling('[data-item=date]').set time.strftime('%m/%d/%Y')

      # bootstrap-timepicker asynchronously re-selects part of its text on focus/keydown
      # (setTimeout-based). Simulated per-character typing races that, so a keystroke can
      # land on a stale selection and overwrite digits instead of appending (e.g. saving
      # "07:02" instead of "17:46"). Set the value directly and fire `change`, which is
      # what App.UiElement.basedate#bindEvents listens for, to avoid the race entirely.
      time_field = field_time.sibling('[data-item=time]')
      time_value = time.strftime('%H:%M')
      execute_script(<<~JS, time_field, time_value)
        arguments[0].value = arguments[1];
        arguments[0].dispatchEvent(new Event('change', { bubbles: true }));
      JS
      expect(time_field.value).to eq time_value

      click '.js-submit'

      expect(Ticket.last).to have_attributes date_test: date, datetime_test: time
    end

    it 'allows to save with cleared value' do
      field_date.sibling('[data-item=date]').click
      find('.datepicker .clear').click
      field_time.sibling('[data-item=date]').click
      find('.datepicker .clear').click

      click '.js-submit'

      expect(Ticket.last).to have_attributes date_test: nil, datetime_test: nil
    end
  end

  context 'when state options have a special translation', authenticated_as: :authenticate do
    let(:admin_de) { create(:admin, preferences: { locale: 'de-de' }) }

    context 'when translated state option has a single quote' do
      def authenticate
        open_tranlation = Translation.where(locale: 'de-de', source: 'open')
        open_tranlation.update(target: "off'en")

        admin_de
      end

      it 'shows the translated state options correctly' do
        visit 'ticket/create'

        expect(page).to have_select('state_id', with_options: ["off'en"])
      end
    end
  end

  describe 'default priority', authenticated_as: :authenticate do
    let(:template)         { create(:template, :dummy_data) }
    let(:ticket_priority)  { create(:ticket_priority, default_create: true) }
    let(:another_priority) { Ticket::Priority.find(1) }
    let(:priority_field)   { find('[name=priority_id]') }

    def authenticate
      template
      ticket_priority
      true
    end

    it 'shows default priority on load' do
      visit 'ticket/create'

      expect(priority_field.value).to eq ticket_priority.id.to_s
    end

    it 'does not reset to default priority on reload' do
      visit 'ticket/create'

      taskbar_timestamp = Taskbar.last.updated_at

      priority_field.select another_priority.name

      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      refresh

      expect(priority_field.reload.value).to eq another_priority.id.to_s
    end

    it 'saves default priority' do
      visit 'ticket/create'
      use_template template
      click '.js-submit'

      expect(Ticket.last).to have_attributes(priority: ticket_priority)
    end

    it 'saves different priority if overriden' do
      visit 'ticket/create'
      use_template template
      priority_field.select another_priority.name
      click '.js-submit'

      expect(Ticket.last).to have_attributes(priority: another_priority)
    end
  end

  describe 'Tree select default values', db_strategy: :reset do
    let(:tree_field_name)       { SecureRandom.hex(10) }
    let(:multi_tree_field_name) { SecureRandom.hex(10) }

    def setup_attributes
      create(:object_manager_attribute_tree_select, :shown_screen, name: tree_field_name, display: tree_field_name, default: 'Incident::Hardware::Mouse')
      create(:object_manager_attribute_multi_tree_select, :shown_screen, name: multi_tree_field_name, display: multi_tree_field_name, default: ['Incident', 'Incident::Hardware::Mouse'])
      ObjectManager::Attribute.migration_execute
    end

    shared_examples 'prefilling the default values' do
      it 'prefills the default values' do
        check_tree_select_field_value(tree_field_name, 'Incident::Hardware::Mouse')

        expect(page).to have_css("div[data-attribute-name='#{multi_tree_field_name}'] span.token-label", exact_text: 'Incident')
        expect(page).to have_css("div[data-attribute-name='#{multi_tree_field_name}'] span.token-label", exact_text: 'Incident › Hardware › Mouse')
        expect(find("select[name='#{multi_tree_field_name}']", visible: :all).value).to contain_exactly('Incident', 'Incident::Hardware::Mouse')
      end
    end

    context 'when agent', authenticated_as: :authenticate do
      let(:customer) { create(:customer) }

      def authenticate
        setup_attributes
        customer
        true
      end

      before do
        visit 'ticket/create'
        wait_for_core_workflow
      end

      include_examples 'prefilling the default values'

      it 'saves the changed tree select value' do
        set_tree_select_value(tree_field_name, 'Incident::Hardware::Keyboard')
        check_tree_select_field_value(tree_field_name, 'Incident::Hardware::Keyboard')

        fill_in 'Title', with: 'test'
        find('.richtext-content').send_keys 'test'
        set_tree_select_value('group_id', Group.first.name)

        find('[name=customer_id_completion]').fill_in with: customer.firstname
        find("li.recipientList-entry.js-object[data-object-id='#{customer.id}']").click

        click '.js-submit'
        wait.until { Ticket.last[tree_field_name] == 'Incident::Hardware::Keyboard' }
      end
    end

    context 'when customer', authenticated_as: :authenticate do
      def authenticate
        setup_attributes
        create(:customer)
      end

      before do
        visit 'customer_ticket_new'
        wait_for_core_workflow
      end

      include_examples 'prefilling the default values'

      it 'saves the changed multi tree select value' do
        within("div[data-attribute-name='#{multi_tree_field_name}']") do
          find(".token[data-value='Incident'] .js-remove").click
          find(".token[data-value='Incident::Hardware::Mouse'] .js-remove").click
        end
        page.evaluate_script("document.querySelector(\"div[data-attribute-name='#{multi_tree_field_name}'] .js-optionsList li[data-value='Change request'] .searchableSelect-option-text\").click()")

        fill_in 'Title', with: 'test'
        find('.richtext-content').send_keys 'test'
        set_tree_select_value('group_id', Group.first.name)

        click '.js-submit'
        wait.until { Ticket.last[multi_tree_field_name] == ['Change request'] }
      end
    end
  end
end
