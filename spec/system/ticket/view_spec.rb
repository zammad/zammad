# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket views', authenticated_as: :authenticate, type: :system do
  def authenticate
    true
  end

  context 'macros' do
    let(:group1)              { create(:group) }
    let(:group2)              { create(:group) }
    let(:macro_without_group) { create(:macro) }
    let(:macro_note)          { create(:macro, perform: { 'article.note'=>{ 'body' => 'macro body', 'internal' => 'true', 'subject' => 'macro note' } }) }
    let(:macro_group1)        { create(:macro, groups: [group1]) }
    let(:macro_group2)        { create(:macro, groups: [group2]) }
    let(:ticket1)             { create(:ticket, group: group1) }
    let(:ticket2)             { create(:ticket, group: group2) }

    describe 'group-dependent macros' do
      let(:agent) { create(:agent, groups: Group.all) }

      def authenticate
        ticket1 && ticket2
        macro_without_group && macro_group1 && macro_group2
        agent
      end

      it 'shows only non-group macro when ticket does not match any group macros' do
        visit '#ticket/view/all_open'

        within(:active_content) do
          display_macro_batches Ticket.first

          expect(page).to have_selector(:macro_batch, macro_without_group.id)
            .and(have_no_selector(:macro_batch, macro_group1.id))
            .and(have_no_selector(:macro_batch, macro_group2.id))
        end
      end

      it 'shows non-group and matching group macros for matching ticket' do
        visit '#ticket/view/all_open'

        within(:active_content) do
          display_macro_batches ticket1

          expect(page).to have_selector(:macro_batch, macro_without_group.id)
            .and(have_selector(:macro_batch, macro_group1.id))
            .and(have_no_selector(:macro_batch, macro_group2.id))
        end
      end
    end

    describe 'macro article creation' do
      def authenticate
        macro_note
        true
      end

      it 'can use macro to create article' do
        visit '#ticket/view/all_open'

        within(:active_content) do
          display_macro_batches Ticket.first

          move_mouse_to find(:macro_batch, macro_note.id)
          release_mouse

          expect do
            wait.until { Ticket.first.articles.last.subject == 'macro note' }
          end.not_to raise_error
        end
      end
    end

    context 'when saving is blocked by one of selected tickets' do
      let(:ticket)               { Ticket.first }
      let(:core_workflow_action) { { 'ticket.priority_id': { operator: 'remove_option', remove_option: '3' } } }
      let(:core_workflow)        { create(:core_workflow, :active_and_screen, :perform_action) }

      let(:macro_perform) do
        {
          'ticket.priority_id': { pre_condition: 'specific', value: 3.to_s }
        }
      end

      let(:macro_priority) { create(:macro, perform: macro_perform) }

      def authenticate
        core_workflow && macro_priority && ticket1

        true
      end

      it 'shows modal with blocking ticket title' do
        visit '#ticket/view/all_open'

        within(:active_content) do
          display_macro_batches ticket

          move_mouse_to find(:macro_batch, macro_priority.id)
          release_mouse

          in_modal do
            expect(page).to have_text(ticket.title)
          end
        end
      end
    end

    context 'with macro batch overlay' do
      shared_examples "adding 'small' class to macro element" do
        it 'adds a "small" class to the macro element' do
          within(:active_content) do
            display_macro_batches Ticket.first

            expect(page).to have_selector('.batch-overlay-macro-entry.small')
          end
        end
      end

      shared_examples "not adding 'small' class to macro element" do
        it 'does not add a "small" class to the macro element' do
          within(:active_content) do
            display_macro_batches Ticket.first

            expect(page).to have_no_selector('.batch-overlay-macro-entry.small')
          end
        end
      end

      shared_examples 'showing all macros' do
        it 'shows all macros' do
          within(:active_content) do
            display_macro_batches Ticket.first

            expect(page).to have_selector('.batch-overlay-macro-entry', count: all)
          end
        end
      end

      shared_examples 'showing some macros' do |count|
        it 'shows all macros' do
          within(:active_content) do
            display_macro_batches Ticket.first

            expect(page).to have_selector('.batch-overlay-macro-entry', count: count)
          end
        end
      end

      def authenticate
        Macro.destroy_all && create_list(:macro, all)
        true
      end

      before do
        visit '#ticket/view/all_open'
      end

      context 'with few macros' do
        let(:all) { 15 }

        context 'when on large screen', screen_size: :desktop do
          it_behaves_like 'showing all macros'
          it_behaves_like "not adding 'small' class to macro element"
        end

        context 'when on small screen', screen_size: :tablet do
          it_behaves_like 'showing all macros'
          it_behaves_like "not adding 'small' class to macro element"
        end

      end

      context 'with many macros' do
        let(:all) { 50 }

        context 'when on large screen', screen_size: :desktop do
          it_behaves_like 'showing some macros', 32
        end

        context 'when on small screen', screen_size: :tablet do
          it_behaves_like 'showing some macros', 24
          it_behaves_like "adding 'small' class to macro element"
        end
      end
    end
  end

  context 'when performing a Bulk action' do
    context 'when creating a Note', authenticated_as: :user do
      let(:group)    { create(:group) }
      let(:user)     { create(:admin, groups: [group]) }
      let(:ticket1)  { create(:ticket, state_name: 'open', owner: user, group: group) }
      let(:ticket2)  { create(:ticket, state_name: 'open', owner: user, group: group) }
      let(:note)     { Faker::Lorem.sentence }

      it 'adds note to all selected tickets' do
        ticket1 && ticket2

        visit 'ticket/view/my_assigned'

        within :active_content do
          all('.js-checkbox-field', count: 2).each(&:click)
          click '.js-confirm'
          find('.js-confirm-step textarea').fill_in with: note
          click '.js-submit'
        end

        expect do
          wait.until { [ ticket1.articles.last&.body, ticket2.articles.last&.body ] == [note, note] }
        end.not_to raise_error
      end
    end

    # https://github.com/zammad/zammad/issues/3568
    # We need a manual ticket creation to test the correct behaviour of the bulk functionality, because of some
    #   leftovers after the creation in the the javascript assets store.
    context 'when performed a manual Ticket creation', authenticated_as: :agent do
      let(:customer)  { create(:customer) }
      let(:group)     { Group.find_by(name: 'Users') }
      let(:agent)     { create(:agent, groups: [group]) }
      let!(:template) { create(:template, :dummy_data, group: group, owner: agent, customer: customer) }

      before do
        visit 'ticket/create'

        within(:active_content) do
          use_template(template)

          click('.js-submit')

          find('.ticket-article-item')
        end
      end

      it 'check that no duplicated article was created after usage of bulk action' do
        click('.menu-item[href="#ticket/view"]')

        created_ticket_id = Ticket.last.id

        within(:active_content) do
          click("tr[data-id='#{created_ticket_id}'] .js-checkbox-field")

          find('select[name="priority_id"] option[value="1"]').select_option

          click('.js-confirm')
          click('.js-submit')

          await_empty_ajax_queue

          # Check if still only one article exists on the ticket.
          click("tr[data-id='#{created_ticket_id}'] a")
          expect(page).to have_css('.ticket-article-item', count: 1)
        end
      end
    end

    context 'when saving is blocked by one of selected tickets', authenticated_as: :pre_authentication do
      let(:core_workflow) { create(:core_workflow, :active_and_screen, :perform_action) }
      let(:ticket1)       { create(:ticket, group: Group.first) }

      def pre_authentication
        core_workflow && ticket1

        true
      end

      it 'shows modal with blocking ticket title' do
        visit 'ticket/view/all_open'

        within(:active_content) do
          find("tr[data-id='#{ticket1.id}']").check('bulk', allow_label_click: true)
          select '3 high', from: 'priority_id'
          click '.js-confirm'
          click '.js-submit'

          in_modal do
            expect(page).to have_text(ticket1.title)
          end
        end
      end
    end
  end

  context 'Setting "ui_table_group_by_show_count"', authenticated_as: :authenticate, db_strategy: :reset do
    let(:custom_attribute) { create(:object_manager_attribute_select, name: 'grouptest') }
    let(:tickets) do
      [
        create(:ticket, group: Group.find_by(name: 'Users')),
        create(:ticket, group: Group.find_by(name: 'Users'), grouptest: 'key_1'),
        create(:ticket, group: Group.find_by(name: 'Users'), grouptest: 'key_2'),
        create(:ticket, group: Group.find_by(name: 'Users'), grouptest: 'key_1')
      ]
    end

    def authenticate
      custom_attribute
      ObjectManager::Attribute.migration_execute
      tickets
      Overview.find_by(name: 'Open Tickets').update(group_by: custom_attribute.name)
      Setting.set('ui_table_group_by_show_count', true)
      true
    end

    it 'shows correct ticket counts' do
      visit 'ticket/view/all_open'

      within(:active_content) do
        expect(page).to have_css('.js-tableBody td b', text: '(1)')
          .and(have_css('.js-tableBody td b', text: 'value_1 (2)'))
          .and(have_css('.js-tableBody td b', text: 'value_2 (1)'))
      end
    end
  end

  context 'Customer', authenticated_as: :authenticate do
    let(:customer) { create(:customer, :with_org) }
    let(:ticket)   { create(:ticket, customer: customer) }

    def authenticate
      ticket
      customer
    end

    it 'shows ticket in my tickets' do
      visit 'ticket/view/my_tickets'
      expect(page).to have_text(ticket.title)
    end

    it 'shows ticket in my organization tickets' do
      visit 'ticket/view/my_tickets'
      click_on 'My Organization Tickets'
      expect(page).to have_text(ticket.title)
    end
  end

  describe 'Grouping by custom attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      custom_attribute
      ObjectManager::Attribute.migration_execute
      tickets
      Overview.find_by(link: 'all_unassigned').update(group_by: custom_attribute.name)
      true
    end

    context 'when sorted by custom object date' do
      let(:custom_attribute) { create(:object_manager_attribute_date, name: 'cdate') }

      let(:tickets) do
        [
          create(:ticket, group: Group.find_by(name: 'Users'), cdate: '2021-08-18'),
          create(:ticket, group: Group.find_by(name: 'Users'), cdate: '2019-01-19'),
          create(:ticket, group: Group.find_by(name: 'Users'), cdate: '2018-01-17'),
          create(:ticket, group: Group.find_by(name: 'Users'), cdate: '2018-08-19')
        ]
      end

      it 'does show the values grouped and sorted by date key value (yyy-mm-dd) instead of display value' do
        visit 'ticket/view/all_unassigned'

        headers = all('.js-tableBody td[colspan="6"]').map(&:text)

        expect(headers).to eq ['01/17/2018', '08/19/2018', '01/19/2019', '08/18/2021', '-']
      end
    end

    context 'when sorted by custom object select', authenticated_as: :authenticate, db_strategy: :reset do
      let(:custom_attribute) do
        create(:object_manager_attribute_select,
               name:                'cselect',
               data_option_options: {
                 'a' => 'Zzz a',
                 'b' => 'Yyy b',
                 'c' => 'Xxx c',
               })
      end

      let(:tickets) do
        [
          create(:ticket, group: Group.find_by(name: 'Users'), cselect: 'a'),
          create(:ticket, group: Group.find_by(name: 'Users'), cselect: 'b'),
          create(:ticket, group: Group.find_by(name: 'Users'), cselect: 'c')
        ]
      end

      it 'does show the values grouped and sorted by display value instead of key value' do
        visit 'ticket/view/all_unassigned'

        headers = all('.js-tableBody td[colspan="6"]').map(&:text)

        expect(headers).to eq ['-', 'Xxx c', 'Yyy b', 'Zzz a']
      end
    end
  end
end
