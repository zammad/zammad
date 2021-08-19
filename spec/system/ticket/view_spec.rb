# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket views', type: :system do
  context 'macros' do
    let!(:group1)              { create :group }
    let!(:group2)              { create :group }
    let!(:macro_without_group) { create :macro }
    let!(:macro_note)          { create :macro, perform: { 'article.note'=>{ 'body' => 'macro body', 'internal' => 'true', 'subject' => 'macro note' } } }
    let!(:macro_group1)        { create :macro, groups: [group1] }
    let!(:macro_group2)        { create :macro, groups: [group2] }

    it 'supports group-dependent macros' do

      ticket1 = create :ticket, group: group1
      ticket2 = create :ticket, group: group2

      # give user access to all groups including those created
      # by using FactoryBot outside of the example
      group_names_access_map = Group.all.pluck(:name).index_with do |_group_name|
        'full'.freeze
      end

      current_user do |user|
        user.group_names_access_map = group_names_access_map
        user.save!
      end

      # refresh browser to get macro accessable
      refresh
      visit '#ticket/view/all_open'

      within(:active_content) do

        ticket = page.find(:table_row, 1).native

        # click and hold first ticket in table
        click_and_hold(ticket)

        # move ticket to y -ticket.location.y
        move_mouse_by(0, -ticket.location.y + 5)

        # move a bit to the left to display macro batches
        move_mouse_by(-250, 0)

        expect(page).to have_selector(:macro_batch, macro_without_group.id, visible: :visible)
        expect(page).to have_no_selector(:macro_batch, macro_group1.id)
        expect(page).to have_no_selector(:macro_batch, macro_group2.id)

        release_mouse

        refresh

        ticket = page.find(:table_row, ticket1.id).native

        # click and hold first ticket in table
        click_and_hold(ticket)

        # move ticket to y -ticket.location.y
        move_mouse_by(0, -ticket.location.y + 5)

        # move a bit to the left to display macro batches
        move_mouse_by(-250, 0)

        expect(page).to have_selector(:macro_batch, macro_without_group.id, visible: :visible)
        expect(page).to have_selector(:macro_batch, macro_group1.id)
        expect(page).to have_no_selector(:macro_batch, macro_group2.id)

        release_mouse

        refresh

        ticket = page.find(:table_row, ticket2.id).native

        # click and hold first ticket in table
        click_and_hold(ticket)

        # move ticket to y -ticket.location.y
        move_mouse_by(0, -ticket.location.y + 5)

        # move a bit to the left to display macro batches
        move_mouse_by(-250, 0)

        expect(page).to have_selector(:macro_batch, macro_without_group.id, visible: :visible)
        expect(page).to have_no_selector(:macro_batch, macro_group1.id)
        expect(page).to have_selector(:macro_batch, macro_group2.id)

      end
    end

    it 'can use macro to create article' do
      refresh
      visit '#ticket/view/all_open'

      within(:active_content) do
        ticket = page.find(:table_row, Ticket.first.id).native

        # click and hold first ticket in table
        click_and_hold(ticket)

        # move ticket to y -ticket.location.y
        move_mouse_by(0, -ticket.location.y + 5)

        # move a bit to the left to display macro batches
        move_mouse_by(-250, 0)

        expect(page).to have_selector(:macro_batch, macro_note.id, wait: 10)

        macro = find(:macro_batch, macro_note.id)
        move_mouse_to(macro)

        release_mouse

        expect do
          wait(10, interval: 0.1).until { Ticket.first.articles.last.subject == 'macro note' }
        end.not_to raise_error
      end
    end

    context 'with macro batch overlay' do
      shared_examples "adding 'small' class to macro element" do
        it 'adds a "small" class to the macro element' do
          within(:active_content) do

            ticket = page.find(:table_row, Ticket.first.id).native

            display_macro_batches(ticket)

            expect(page).to have_selector('.batch-overlay-macro-entry.small', wait: 10)

            release_mouse
          end
        end
      end

      shared_examples "not adding 'small' class to macro element" do
        it 'does not add a "small" class to the macro element' do
          within(:active_content) do

            ticket = page.find(:table_row, Ticket.first.id).native

            display_macro_batches(ticket)

            expect(page).to have_no_selector('.batch-overlay-macro-entry.small', wait: 10)

            release_mouse
          end
        end
      end

      shared_examples 'showing all macros' do
        it 'shows all macros' do
          within(:active_content) do

            ticket = page.find(:table_row, Ticket.first.id).native

            display_macro_batches(ticket)

            expect(page).to have_selector('.batch-overlay-macro-entry', count: all, wait: 10)

            release_mouse
          end
        end
      end

      shared_examples 'showing some macros' do |count|
        it 'shows all macros' do
          within(:active_content) do

            ticket = page.find(:table_row, Ticket.first.id).native

            display_macro_batches(ticket)

            expect(page).to have_selector('.batch-overlay-macro-entry', count: count, wait: 10)

            release_mouse
          end
        end
      end

      shared_examples 'show macros batch overlay' do
        before do
          Macro.destroy_all && (create_list :macro, all)
          refresh
          page.current_window.resize_to(width, height)
          visit '#ticket/view/all_open'
        end

        context 'with few macros' do
          let(:all) { 15 }

          context 'when on large screen' do
            let(:width) { 1520 }
            let(:height) { 1040 }

            it_behaves_like 'showing all macros'
            it_behaves_like "not adding 'small' class to macro element"
          end

          context 'when on small screen' do
            let(:width) { 1020 }
            let(:height) { 1040 }

            it_behaves_like 'showing all macros'
            it_behaves_like "not adding 'small' class to macro element"
          end

        end

        context 'with many macros' do
          let(:all) { 50 }

          context 'when on large screen' do
            let(:width) { 1520 }
            let(:height) { 1040 }

            it_behaves_like 'showing some macros', 32
          end

          context 'when on small screen' do
            let(:width) { 1020 }
            let(:height) { 1040 }

            it_behaves_like 'showing some macros', 30
            it_behaves_like "adding 'small' class to macro element"
          end
        end
      end

      include_examples 'show macros batch overlay'
    end
  end

  context 'when performing a Bulk action' do
    context 'when creating a Note', authenticated_as: :user do
      let(:group)    { create :group }
      let(:user)     { create :admin, groups: [group] }
      let!(:ticket1) { create(:ticket, state_name: 'open', owner: user, group: group) }
      let!(:ticket2) { create(:ticket, state_name: 'open', owner: user, group: group) }
      let(:note)     { Faker::Lorem.sentence }

      it 'adds note to all selected tickets' do
        visit 'ticket/view/my_assigned'

        within :active_content do
          all('.js-checkbox-field', count: 2).each(&:click)
          click '.js-confirm'
          find('.js-confirm-step textarea').fill_in with: note
          click '.js-submit'
        end

        expect do
          wait(10, interval: 0.1).until { [ ticket1.articles.last&.body, ticket2.articles.last&.body ] == [note, note] }
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
  end

  context 'Setting "ui_table_group_by_show_count"', authenticated_as: :authenticate, db_strategy: :reset do
    let!(:ticket1) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let!(:ticket2) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let!(:ticket3) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let!(:ticket4) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      create :object_manager_attribute_select, name: 'grouptest'
      ObjectManager::Attribute.migration_execute
      ticket1
      ticket2.update(grouptest: 'key_1')
      ticket3.update(grouptest: 'key_2')
      ticket4.update(grouptest: 'key_1')
      Overview.find_by(name: 'Open').update(group_by: 'grouptest')
      Setting.set('ui_table_group_by_show_count', true)
      true
    end

    it 'shows correct ticket counts' do
      visit 'ticket/view/all_open'
      within(:active_content) do
        page.find('.js-tableBody td b', text: '(1)')
        page.find('.js-tableBody td b', text: 'value_1 (2)')
        page.find('.js-tableBody td b', text: 'value_2 (1)')
      end
    end
  end

  context 'Customer', authenticated_as: :authenticate do
    let(:customer) { create(:customer, :with_org) }
    let(:ticket) { create(:ticket, customer: customer) }

    def authenticate
      ticket
      customer
    end

    it 'does basic view test of tickets' do
      visit 'ticket/view/my_tickets'
      expect(page).to have_text(ticket.title, wait: 10)
      click_on 'My Organization Tickets'
      expect(page).to have_text(ticket.title, wait: 10)
    end
  end

  describe 'Grouping' do
    context 'when sorted by custom object date', authenticated_as: :authenticate, db_strategy: :reset do
      let(:ticket1) { create(:ticket, group: Group.find_by(name: 'Users'), cdate: '2018-01-17') }
      let(:ticket2) { create(:ticket, group: Group.find_by(name: 'Users'), cdate: '2018-08-19') }
      let(:ticket3) { create(:ticket, group: Group.find_by(name: 'Users'), cdate: '2019-01-19') }
      let(:ticket4) { create(:ticket, group: Group.find_by(name: 'Users'), cdate: '2021-08-18') }

      def authenticate
        create :object_manager_attribute_date, name: 'cdate'
        ObjectManager::Attribute.migration_execute
        ticket4
        ticket3
        ticket2
        ticket1
        Overview.find_by(link: 'all_unassigned').update(group_by: 'cdate')
        true
      end

      it 'does show the date groups sorted' do
        visit 'ticket/view/all_unassigned'
        text = page.find('.js-tableBody').text(:all)

        expect(text.index('01/17/2018') < text.index('08/19/2018')).to eq(true)
        expect(text.index('08/19/2018') < text.index('01/19/2019')).to eq(true)
        expect(text.index('01/19/2019') < text.index('08/18/2021')).to eq(true)
      end
    end
  end
end
