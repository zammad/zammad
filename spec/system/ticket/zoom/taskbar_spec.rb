# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Taskbar', type: :system do
  describe 'Update of ticket links', authenticated_as: :authenticate do
    let(:ticket1) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:ticket2) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      ticket1
      ticket2
      create(:link, from: ticket1, to: ticket2)
      true
    end

    it 'does update the state of the ticket links' do
      visit "ticket/zoom/#{ticket1.id}"

      # check title changes
      expect(page).to have_text(ticket2.title)
      ticket2.update(title: 'super new title')
      expect(page).to have_text(ticket2.reload.title)

      # check state changes
      expect(page).to have_css('div.links .tasks svg.open')
      ticket2.update(state: Ticket::State.find_by(name: 'closed'))
      expect(page).to have_css('div.links .tasks svg.closed')
    end
  end

  describe 'merging happened in the background', authenticated_as: :user do
    before do
      merged_into_trigger && received_merge_trigger && update_trigger

      visit "ticket/zoom/#{ticket.id}"
      visit "ticket/zoom/#{target_ticket.id}"

      ensure_websocket do
        visit 'dashboard'
      end
    end

    let(:merged_into_trigger)    { create(:trigger, :conditionable, condition_ticket_action: :merged_into) }
    let(:received_merge_trigger) { create(:trigger, :conditionable, condition_ticket_action: :received_merge) }
    let(:update_trigger)         { create(:trigger, :conditionable, condition_ticket_action: :update) }

    let(:ticket)                 { create(:ticket).tap { |t| create(:ticket_article, ticket: t) && TransactionDispatcher.commit } }
    let(:target_ticket)          { create(:ticket).tap { |t| create(:ticket_article, ticket: t) && TransactionDispatcher.commit } }

    let(:user)                   { create(:agent, :preferencable, notification_group_ids: [ticket, target_ticket].map(&:group_id), groups: [ticket, target_ticket].map(&:group)) }

    context 'when merging ticket' do
      before do
        ticket.merge_to(ticket_id: target_ticket.id, user_id: user.id)
      end

      it 'pulses source ticket' do
        expect(page).to have_css("#navigation a.is-modified[data-key=\"Ticket-#{ticket.id}\"]")
      end

      it 'pulses target ticket' do
        expect(page).to have_css("#navigation a.is-modified[data-key=\"Ticket-#{target_ticket.id}\"]")
      end
    end

    context 'when merging and looking at online notifications', :performs_jobs do
      before do
        perform_enqueued_jobs do
          ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
        end

        find('.js-toggleNotifications').click
      end

      it 'shows online notification for source ticket' do
        expect(page).to have_text("Ticket #{ticket.title} was merged into another ticket")
      end

      it 'shows online notification for target ticket' do
        expect(page).to have_text("Another ticket was merged into ticket #{ticket.title}")
      end
    end
  end

  describe 'Tab behaviour - Define default "stay on tab" / "close tab" behavior #257', authenticated_as: :authenticate do
    def authenticate
      Setting.set('ticket_secondary_action', 'closeTabOnTicketClose')
      true
    end

    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    before do
      visit "ticket/zoom/#{ticket.id}"
    end

    it 'does show the default of the system' do
      expect(page).to have_text('Close tab on ticket close')
    end

    it 'does save state for the user preferences' do
      click '.js-attributeBar .dropup div'
      click 'span[data-type=stayOnTab]'
      refresh
      expect(page).to have_text('Stay on tab')
      expect(User.find_by(email: 'admin@example.com').preferences[:secondaryAction]).to eq('stayOnTab')
    end

    it 'does show the correct tab state after update of the ticket (#4094)' do
      select 'closed', from: 'State'
      click '.js-attributeBar .dropup div'
      click 'span[data-type=stayOnTab]'
      click '.js-submit'
      expect(page.find('.js-secondaryActionButtonLabel')).to have_text('Stay on tab')
    end

    context 'Tab behaviour - Close tab on ticket close' do
      it 'does not close the tab without any action' do
        click '.js-submit'
        expect(current_url).to include('ticket/zoom')
      end

      it 'does close the tab on ticket close' do
        select 'closed', from: 'State'
        click '.js-submit'
        expect(current_url).not_to include('ticket/zoom')
      end
    end

    context 'Tab behaviour - Stay on tab' do
      def authenticate
        Setting.set('ticket_secondary_action', 'stayOnTab')
        true
      end

      it 'does not close the tab without any action' do
        click '.js-submit'
        expect(current_url).to include('ticket/zoom')
      end

      it 'does not close the tab on ticket close' do
        select 'closed', from: 'State'
        click '.js-submit'
        expect(current_url).to include('ticket/zoom')
      end
    end

    context 'Tab behaviour - Close tab' do
      def authenticate
        Setting.set('ticket_secondary_action', 'closeTab')
        true
      end

      it 'does close the tab without any action' do
        click '.js-submit'
        expect(current_url).not_to include('ticket/zoom')
      end

      it 'does close the tab on ticket close' do
        select 'closed', from: 'State'
        click '.js-submit'
        expect(current_url).not_to include('ticket/zoom')
      end
    end

    context 'Tab behaviour - Next in overview' do
      let(:ticket1) { create(:ticket, title: SecureRandom.uuid, group: Group.find_by(name: 'Users')) }
      let(:ticket2) { create(:ticket, title: SecureRandom.uuid, group: Group.find_by(name: 'Users')) }
      let(:ticket3) { create(:ticket, title: SecureRandom.uuid, group: Group.find_by(name: 'Users')) }

      def authenticate
        Setting.set('ticket_secondary_action', 'closeNextInOverview')
        ticket1
        ticket2
        ticket3
        true
      end

      before do
        visit 'ticket/view/all_open'
      end

      it 'does change the tab without any action' do
        click_on ticket1.title
        expect(current_url).to include("ticket/zoom/#{ticket1.id}")
        click '.js-submit'
        expect(current_url).to include("ticket/zoom/#{ticket2.id}")
        click '.js-submit'
        expect(current_url).to include("ticket/zoom/#{ticket3.id}")
      end

      # Ported from test/browser/agent_ticket_overview_tab_test.rb: closing the
      #   ticket replaces the task with the next overview ticket instead of
      #   accumulating tabs.
      it 'does replace the task with the next overview ticket on ticket close' do
        click_on ticket1.title
        expect(current_url).to include("ticket/zoom/#{ticket1.id}")

        within(:active_content) do
          select 'closed', from: 'State'
          click '.js-submit'
        end

        expect(current_url).to include("ticket/zoom/#{ticket2.id}")
        expect(page).to have_css('.tasks .task.is-active', text: ticket2.title)

        # The closed ticket's task was replaced, not kept as an additional tab.
        expect(page).to have_no_css('.tasks .task', text: ticket1.title)
      end

      it 'does show default stay on tab if secondary action is not given' do
        click_on ticket1.title
        refresh
        expect(page).to have_text('Stay on tab')
      end
    end

    context 'On ticket switch' do
      let(:ticket1) { create(:ticket, title: SecureRandom.uuid, group: Group.find_by(name: 'Users')) }
      let(:ticket2) { create(:ticket, title: SecureRandom.uuid, group: Group.find_by(name: 'Users')) }

      before do
        visit "ticket/zoom/#{ticket1.id}"
        visit "ticket/zoom/#{ticket2.id}"
      end

      it 'does setup the last behaviour' do
        click '.js-attributeBar .dropup div'
        click 'span[data-type=stayOnTab]'
        wait.until do
          User.find_by(email: 'admin@example.com').preferences['secondaryAction'] == 'stayOnTab'
        end
        visit "ticket/zoom/#{ticket1.id}"
        expect(page).to have_text('Stay on tab')
      end
    end
  end

  describe 'Incorrect notification when closing a tab after setting up an object #2042', db_strategy: :reset do
    let(:ticket) { create(:ticket, group: Group.first) }

    before do
      # Create test ticket before adding the test object attribute.
      ticket

      create(:object_manager_attribute_text, name: 'text_test', display: 'text_test', screens: {
               'edit' => {
                 'ticket.agent' => {
                   'shown'    => true,
                   'required' => true,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute

      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does not show the discard button nor the confirmation dialog' do
      within(:active_content) do
        expect(page).to have_no_css('.js-reset')
      end

      taskbar_tab_close("Ticket-#{ticket.id}", discard_changes: false)

      expect(page).to have_no_css('.modal')
    end
  end

  describe 'Delay non-active taskbars to improve initial loading speed. #5776' do
    let(:tickets) { create_list(:ticket, 3, group: Group.find_by(name: 'Users')) }

    it 'does load tickets freshly and delayed' do
      visit "#ticket/zoom/#{tickets.first.id}"
      visit "#ticket/zoom/#{tickets.second.id}"
      visit "#ticket/zoom/#{tickets.third.id}"
      refresh
      await_empty_ajax_queue
      page.find(".tasks a[data-key=\"Ticket-#{tickets.second.id}\"]").click
      expect(page).to have_text(tickets.second.title)
      page.find(".tasks a[data-key=\"Ticket-#{tickets.first.id}\"]").click
      expect(page).to have_text(tickets.first.title)
      page.find(".tasks a[data-key=\"Ticket-#{tickets.third.id}\"]").click
      expect(page).to have_text(tickets.third.title)
    end
  end

  describe 'Taskbars for missing tickets are never loaded unless switched to #5812' do
    it 'does always complete loading' do
      visit "#ticket/zoom/#{Ticket.first.id}"
      visit '#ticket/zoom/99999999'
      visit '#dashboard'
      refresh
      expect(page).to have_css("#navigation [data-key='Ticket-99999999']", text: 'Not Found')
    end
  end

  describe 'Not loaded tickets do not show the update indicator in taskbar entries #5814' do
    let(:agent_update) { create(:agent, groups: Group.all) }

    it 'does show updated icon when priority is changed' do
      ensure_websocket do
        visit "#ticket/zoom/#{Ticket.first.id}"
        visit '#dashboard'
        refresh
      end
      expect(page).to have_no_css('#navigation .icon-status-modified-inner-circle')
      sleep 2

      Ticket.first.update(priority: Ticket::Priority.find_by(name: '3 high'), updated_by: agent_update)
      expect(page).to have_css('#navigation .icon-status-modified-inner-circle')
    end
  end
end
