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
      group_names_access_map = Group.all.pluck(:name).each_with_object({}) do |group_name, result|
        result[group_name] = 'full'.freeze
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

    it 'can use macro to create article', authenticated_as: true do
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

        await_empty_ajax_queue

        expect(Ticket.first.articles.last.subject).to eq('macro note')
      end
    end
  end

  context 'bulk note', authenticated_as: :user do
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

      await_empty_ajax_queue

      expect([
               ticket1.articles.last&.body,
               ticket2.articles.last&.body
             ]).to be_all note
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
      expect(page).to have_text(ticket.title)
      click_on 'My Organization Tickets'
      expect(page).to have_text(ticket.title)
    end
  end
end
