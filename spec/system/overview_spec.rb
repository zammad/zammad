# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Overview', type: :system do
  context 'when logged in as customer', authenticated_as: :customer do
    let!(:customer)      { create(:customer) }
    let!(:main_overview) { create(:overview) }
    let!(:other_overview) do
      create(:overview, condition: {
               'ticket.state_id' => {
                 operator: 'is',
                 value:    Ticket::State.where(name: %w[merged]).pluck(:id),
               },
             })
    end

    it 'shows create button when customer has no tickets' do
      visit "ticket/view/#{main_overview.link}"

      within :active_content do
        expect(page).to have_text 'Create your first ticket'
      end
    end

    def authenticate
      Setting.set('customer_ticket_create', false)
      customer
    end

    it 'does not show create button when ticket creation via web is disabled', authenticated_as: :authenticate do
      visit "ticket/view/#{main_overview.link}"

      within :active_content do
        expect(page).to have_text 'You currently don\'t have any tickets.'
      end
    end

    it 'shows overview-specific message if customer has tickets in other overview', performs_jobs: true do
      perform_enqueued_jobs only: TicketUserTicketCounterJob do
        create(:ticket, customer: customer)
      end

      visit "ticket/view/#{other_overview.link}"

      within :active_content do
        expect(page).to have_text 'You have no tickets'
      end
    end

    it 'replaces button with overview-specific message when customer creates a ticket', performs_jobs: true do
      visit "ticket/view/#{other_overview.link}"
      visit 'customer_ticket_new'

      find('[name=title]').fill_in with: 'Title'
      find(:richtext).send_keys 'content'
      set_tree_select_value('group_id', Group.first.name)
      click '.js-submit'

      perform_enqueued_jobs only: TicketUserTicketCounterJob

      visit "ticket/view/#{other_overview.link}"
      within :active_content do
        expect(page).to have_text 'You have no tickets'
      end
    end
  end

  context 'sorting when group by is set', authenticated_as: :user do
    let(:user) { create(:agent, groups: [group_c, group_a, group_b]) }

    let(:group_a) { create(:group, name: 'aaa') }
    let(:group_b) { create(:group, name: 'bbb') }
    let(:group_c) { create(:group, name: 'ccc') }

    let(:ticket1) { create(:ticket, group: group_a, priority_id: 1, customer: user) }
    let(:ticket2) { create(:ticket, group: group_c, priority_id: 2, customer: user) }
    let(:ticket3) { create(:ticket, group: group_b, priority_id: 3, customer: user) }

    let(:overview) do
      create(:overview, group_by: group_key, group_direction: group_direction, condition: {
               'ticket.customer_id' => {
                 operator: 'is',
                 value:    user.id
               }
             })
    end

    before do
      ticket1 && ticket2 && ticket3

      visit "ticket/view/#{overview.link}"
    end

    context 'when grouping by priority' do
      let(:group_key) { 'priority' }

      context 'when group direction is default' do
        let(:group_direction) { nil }

        it 'sorts groups 1 > 3' do
          within :active_content do
            expect(all('.table-overview table b').map(&:text)).to eq ['1 low', '2 normal', '3 high']
          end
        end

        it 'does not show duplicates when any ticket attribute is updated using bulk update' do
          find("tr[data-id='#{ticket3.id}']").check('bulk', allow_label_click: true)
          select '2 normal', from: 'priority_id'

          click '.js-confirm'
          find('.js-confirm-step textarea').fill_in with: 'test tickets ordering'
          click '.js-submit'

          within :active_content do
            expect(page).to have_css("tr[data-id='#{ticket3.id}']", count: 1)
          end
        end
      end

      context 'when group direction is ASC' do
        let(:group_direction) { 'ASC' }

        it 'sorts groups 1 > 3' do
          within :active_content do
            expect(all('.table-overview table b').map(&:text)).to eq ['1 low', '2 normal', '3 high']
          end
        end
      end

      context 'when group direction is DESC' do
        let(:group_direction) { 'DESC' }

        it 'sorts groups 3 > 1' do
          within :active_content do
            expect(all('.table-overview table b').map(&:text)).to eq ['3 high', '2 normal', '1 low']
          end
        end
      end
    end

    context 'when grouping by groups' do
      let(:group_key) { 'group' }
      let(:group_direction) { 'ASC' }

      it 'sorts groups a > b > c' do
        within :active_content do
          expect(all('.table-overview table b').map(&:text)).to eq %w[aaa bbb ccc]
        end
      end

      it 'updates table grouping when updated using bulk update' do
        find("tr[data-id='#{ticket1.id}']").check('bulk', allow_label_click: true)
        find("tr[data-id='#{ticket2.id}']").check('bulk', allow_label_click: true)
        find("tr[data-id='#{ticket3.id}']").check('bulk', allow_label_click: true)

        find('[data-attribute-name="group_id"]').click
        find('li', text: 'aaa').click

        click '.js-confirm'
        find('.js-confirm-step textarea').fill_in with: 'test tickets grouping'
        click '.js-submit'

        within :active_content do
          expect(page)
            .to have_text('aaa')
            .and have_no_text('bbb')
            .and have_no_text('ccc')
        end
      end
    end

    context 'when grouping by tree_selects', authenticated_as: :authenticate, db_strategy: :reset do
      def authenticate
        create(:object_manager_attribute_tree_select, name: 'tree_select_field', display: 'Tree Select Field', data_option: data_option)
        ObjectManager::Attribute.migration_execute
        user
      end

      let(:data_option) do
        {
          'options'    => [
            {
              'name'     => 'a',
              'value'    => 'a',
              'children' => [
                {
                  'name'  => '1',
                  'value' => 'a::1',
                }
              ]
            },
            {
              'name'     => 'b',
              'value'    => 'b',
              'children' => [
                {
                  'name'  => '1',
                  'value' => 'b::1',
                },
                {
                  'name'  => '2',
                  'value' => 'b::2',
                }
              ]
            },
            {
              'name'     => 'c',
              'value'    => 'c',
              'children' => [
                {
                  'name'  => '1',
                  'value' => 'c::1',
                },
                {
                  'name'  => '2',
                  'value' => 'c::2',
                },
                {
                  'name'  => '3',
                  'value' => 'c::3',
                },
              ]
            },
          ],
          'default'    => '',
          'null'       => true,
          'relation'   => '',
          'maxlength'  => 255,
          'nulloption' => true,
        }
      end

      let(:ticket1) { create(:ticket, group: group_a, priority_id: 1, customer: user, tree_select_field: 'a::1') }
      let(:ticket2)   { create(:ticket, group: group_c, priority_id: 2, customer: user, tree_select_field: 'b::2') }
      let(:ticket3)   { create(:ticket, group: group_b, priority_id: 3, customer: user, tree_select_field: 'c::3') }
      let(:group_key) { 'tree_select_field' }

      context 'when group direction is default' do
        let(:group_direction) { nil }

        it 'sorts groups a::1 > b::2 > c::3' do
          within :active_content do
            expect(all('.table-overview table b').map(&:text)).to eq %w[a::1 b::2 c::3]
          end
        end
      end

      context 'when group direction is ASC' do
        let(:group_direction) { 'ASC' }

        it 'sorts groups a::1 > b::2 > c::3' do
          within :active_content do
            expect(all('.table-overview table b').map(&:text)).to eq %w[a::1 b::2 c::3]
          end
        end
      end

      context 'when group direction is DESC' do
        let(:group_direction) { 'DESC' }

        it 'sorts groups c::3 > b::2 > a::1' do
          within :active_content do
            expect(all('.table-overview table b').map(&:text)).to eq %w[c::3 b::2 a::1]
          end
        end
      end
    end
  end

  context 'when multiselect is choosen as column', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_multiselect, data_option: data_option, name: attribute_name)
      ObjectManager::Attribute.migration_execute
      user
    end

    let(:user) { create(:agent, groups: [group]) }

    let(:attribute_name) { 'multiselect' }
    let(:options_hash) do
      {
        'key_1' => 'display_value_1',
        'key_2' => 'display_value_2',
        'key_3' => 'display_value_3',
        'key_4' => 'display_value_4',
        'key_5' => 'display_value_5'
      }
    end
    let(:data_option) { { options: options_hash, default: '' } }
    let(:group)       { create(:group, name: 'aaa') }

    let(:ticket) { create(:ticket, group: group, customer: user, multiselect: multiselect_value) }

    let(:view) { { 's'=>%w[number title multiselect] } }
    let(:condition) do
      {
        'ticket.customer_id' => {
          operator: 'is',
          value:    user.id
        }
      }
    end
    let(:overview) { create(:overview, condition: condition, view: view) }

    let(:overview_table_selector) { '.table-overview .js-tableBody' }

    before do
      ticket

      visit "ticket/view/#{overview.link}"
    end

    context 'with nil multiselect value' do
      let(:multiselect_value) { nil }
      let(:expected_text) { '-' }

      it "shows dash '-' for tickets" do
        within :active_content, overview_table_selector do
          expect(page).to have_css 'tr.item td', text: expected_text
        end
      end
    end

    context 'with a single multiselect value' do
      let(:multiselect_value) { ['key_4'] }
      let(:expected_text) { 'display_value_4' }

      it 'shows the display value for tickets' do
        within :active_content, overview_table_selector do
          expect(page).to have_css 'tr.item td', text: expected_text
        end
      end
    end

    context 'with multiple multiselect values' do
      let(:multiselect_value) { %w[key_2 key_3 key_5] }
      let(:expected_text) { 'display_value_2, display_value_3, display_value_5' }

      it 'shows comma seperated diaplay value for tickets' do
        within :active_content, overview_table_selector do
          expect(page).to have_css 'tr.item td', text: expected_text
        end
      end
    end
  end

  context 'when only one attribute is visible', authenticated_as: :user do
    let(:user) { create(:agent, groups: [group]) }
    let(:group)  { create(:group, name: 'aaa') }
    let(:ticket) { create(:ticket, group: group, customer: user) }

    let(:view) { { 's' => %w[title] } }
    let(:condition) do
      {
        'ticket.customer_id' => {
          operator: 'is',
          value:    user.id
        }
      }
    end
    let(:overview) { create(:overview, condition: condition, view: view) }

    let(:overview_table_head_selector) { 'div.table-overview table.table thead' }
    let(:expected_header_text) { 'TITLE' }

    before do
      ticket

      visit "ticket/view/#{overview.link}"
    end

    it 'shows only the title column' do
      within :active_content, overview_table_head_selector do
        expect(page).to have_css('th.js-tableHead[data-column-key="title"]', text: expected_header_text)
      end
    end
  end

  context 'when dragging table columns' do
    let(:overview) { create(:overview) }

    before do
      visit "ticket/view/#{overview.link}"
    end

    shared_examples 'resizing table columns' do
      it 'resizes table columns' do
        initial_number_width = find_all('.js-tableHead')[1].native.size.width.to_i
        initial_title_width = find_all('.js-tableHead')[2].native.size.width.to_i

        column_resize_handle = find_all('.js-col-resize')[0]

        # Drag the first column resize handle to the left.
        #   Move the cursor horizontally by 100 pixels.
        #   Finally, drop the handle to resize the column.
        page.driver.browser.action
          .move_to(column_resize_handle.native)
          .click_and_hold
          .move_by(-100, 0)
          .release
          .perform

        final_number_width = find_all('.js-tableHead')[1].native.size.width.to_i
        final_title_width = find_all('.js-tableHead')[2].native.size.width.to_i

        expect(final_number_width).to be < initial_number_width
        expect(final_title_width).to be > initial_title_width
      end
    end

    context 'with mouse input' do
      it_behaves_like 'resizing table columns'
    end

    # TODO: Add a test example for touch input once the tablet emulation mode starts working in the CI.
  end

  # https://github.com/zammad/zammad/issues/4409
  context 'when sorting by display values', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      custom_field
      ObjectManager::Attribute.migration_execute
      true
    end

    let(:overview)     { create(:overview, view: { 's'=>%w[number title overview_test] }) }
    let(:custom_field) { create("object_manager_attribute_#{field_type}", name: :overview_test, data_option: data_option) }
    let(:data_option)  { { options: options_hash, translate: translate, default: '' } }
    let(:translate)    { false }
    let(:group)        { Group.first }

    let(:options_hash) do
      {
        'key_1' => 'A value',
        'key_2' => 'D value',
        'key_3' => 'B value',
        'key_4' => 'C value',
      }
    end

    let(:custom_sorted_array) do
      [
        { value: 'key_1', name: 'C value' },
        { value: 'key_3', name: 'A value' },
        { value: 'key_2', name: 'B value' },
        { value: 'key_4', name: 'D value' },
      ]
    end

    let(:translations_hash) do
      {
        'A value' => 'Pirma vertė',
        'B value' => 'Antra vertė',
        'C value' => 'Trečia vertė',
        'D value' => 'Ketvirta vertė'
      }
    end

    before do
      Ticket.destroy_all

      translations_hash.each { |key, value| create(:translation, locale: 'en-us', source: key, target: value) }

      ticket_1 && ticket_2 && ticket_3 && ticket_4

      visit "ticket/view/#{overview.link}"

      find('[data-column-key=overview_test] .js-sort').click
    end

    context 'when field is select' do
      let(:field_type) { 'select' }

      let(:ticket_1) { create(:ticket, title: 'A ticket', overview_test: 'key_1', group: group) }
      let(:ticket_2) { create(:ticket, title: 'B ticket', overview_test: 'key_2', group: group) }
      let(:ticket_3) { create(:ticket, title: 'C ticket', overview_test: 'key_3', group: group) }
      let(:ticket_4) { create(:ticket, title: 'D ticket', overview_test: 'key_4', group: group) }

      context 'when custom sort is on' do
        let(:data_option) { { options: custom_sorted_array, default: '', customsort: 'on' } }

        it 'sorts tickets correctly' do
          within '.js-tableBody' do
            expect(page)
              .to have_css('tr:nth-child(1)', text: ticket_1.title)
              .and have_css('tr:nth-child(2)', text: ticket_3.title)
              .and have_css('tr:nth-child(3)', text: ticket_2.title)
              .and have_css('tr:nth-child(4)', text: ticket_4.title)
          end
        end
      end

      context 'when custom sort is off' do
        it 'sorts tickets correctly' do
          within '.js-tableBody' do
            expect(page)
              .to have_css('tr:nth-child(1)', text: ticket_1.title)
              .and have_css('tr:nth-child(2)', text: ticket_3.title)
              .and have_css('tr:nth-child(3)', text: ticket_4.title)
              .and have_css('tr:nth-child(4)', text: ticket_2.title)
          end
        end
      end

      context 'when display values are translated' do
        let(:translate) { true }

        it 'sorts tickets correctly' do
          within '.js-tableBody' do
            expect(page)
              .to have_css('tr:nth-child(1)', text: ticket_3.title)
              .and have_css('tr:nth-child(2)', text: ticket_2.title)
              .and have_css('tr:nth-child(3)', text: ticket_1.title)
              .and have_css('tr:nth-child(4)', text: ticket_4.title)
          end
        end
      end
    end

    context 'when field is multiselect' do
      let(:field_type) { 'multiselect' }

      let(:ticket_1) { create(:ticket, title: 'A ticket', overview_test: '{key_1}', group: group) }
      let(:ticket_2) { create(:ticket, title: 'B ticket', overview_test: '{key_2,key_3}', group: group) }
      let(:ticket_3) { create(:ticket, title: 'C ticket', overview_test: '{key_4,key_3,key_2}', group: group) }
      let(:ticket_4) { create(:ticket, title: 'D ticket', overview_test: '{key_2}', group: group) }

      context 'when custom sort is on' do
        let(:data_option) { { options: custom_sorted_array, default: '', customsort: 'on' } }

        it 'sorts tickets correctly' do
          within '.js-tableBody' do
            expect(page)
              .to have_css('tr:nth-child(1)', text: ticket_1.title)
              .and have_css('tr:nth-child(2)', text: ticket_2.title)
              .and have_css('tr:nth-child(3)', text: ticket_3.title)
              .and have_css('tr:nth-child(4)', text: ticket_4.title)
          end
        end
      end

      context 'when custom sort is off' do
        it 'sorts tickets correctly' do
          within '.js-tableBody' do
            expect(page)
              .to have_css('tr:nth-child(1)', text: ticket_1.title)
              .and have_css('tr:nth-child(2)', text: ticket_3.title)
              .and have_css('tr:nth-child(3)', text: ticket_2.title)
              .and have_css('tr:nth-child(4)', text: ticket_4.title)
          end
        end
      end

      context 'when display values are translated' do
        let(:translate) { true }

        it 'sorts tickets correctly' do
          within '.js-tableBody' do
            expect(page)
              .to have_css('tr:nth-child(1)', text: ticket_2.title)
              .and have_css('tr:nth-child(2)', text: ticket_3.title)
              .and have_css('tr:nth-child(3)', text: ticket_4.title)
              .and have_css('tr:nth-child(4)', text: ticket_1.title)
          end
        end
      end
    end
  end

  # https://github.com/zammad/zammad/issues/4409
  # Touched by above issue, but not directly related
  context 'when sorting by select field without options' do
    let(:overview) do
      create(:overview, condition: {
               'ticket.state_id' => {
                 operator: 'is',
                 value:    Ticket::State.where(name: %w[new open closed]).pluck(:id),
               },
             })
    end

    let(:ticket_1) { create(:ticket, title: 'A ticket', state_name: 'open', group: group) }
    let(:ticket_2) { create(:ticket, title: 'B ticket', state_name: 'closed', group: group) }
    let(:ticket_3) { create(:ticket, title: 'C ticket', state_name: 'new', group: group) }
    let(:group)    { Group.first }

    before do
      if defined?(translations_hash)
        translations_hash.each do |key, value|
          Translation.find_or_create_by(locale: 'en-us', source: key).update!(target: value)
        end
      end

      Ticket.destroy_all

      ticket_1 && ticket_2 && ticket_3

      visit "ticket/view/#{overview.link}"

      find('[data-column-key=state_id] .js-sort').click
    end

    it 'sorts tickets correctly' do
      within '.js-tableBody' do
        expect(page)
          .to have_css('tr:nth-child(1)', text: ticket_2.title)
          .and have_css('tr:nth-child(2)', text: ticket_3.title)
          .and have_css('tr:nth-child(3)', text: ticket_1.title)
      end
    end

    context 'when states are translated' do
      let(:translations_hash) { { 'closed' => 'zzz closed' } }

      it 'sorts tickets correctly' do
        within '.js-tableBody' do
          expect(page)
            .to have_css('tr:nth-child(1)', text: ticket_3.title)
            .and have_css('tr:nth-child(2)', text: ticket_1.title)
            .and have_css('tr:nth-child(3)', text: ticket_2.title)
        end
      end
    end
  end
end
