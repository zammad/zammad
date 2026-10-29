# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Sidebar > Ticket', type: :system do
  # https://github.com/zammad/zammad/issues/2671
  describe 'Pending time field in ticket sidebar', authenticated_as: :customer do
    let(:customer) { create(:customer) }
    let(:ticket)   { create(:ticket, customer: customer, pending_time: 1.day.from_now, state: Ticket::State.lookup(name: 'pending reminder')) }

    it 'not shown to customer' do
      visit "ticket/zoom/#{ticket.id}"

      within :active_content do
        expect(page).to have_css('.ticketZoom-header .ticket-number', text: ticket.number)
        expect(page).to have_no_css('.controls[data-name=pending_time]')
      end
    end
  end

  describe 'Pending time field in ticket sidebar as agent' do
    before do
      ticket.update(pending_time: 1.day.from_now, state: Ticket::State.lookup(name: 'pending reminder'))

      visit "ticket/zoom/#{ticket.id}"
    end

    let(:ticket) { Ticket.first }

    # has to run asynchronously to keep both Firefox and Safari
    # https://github.com/zammad/zammad/issues/3414
    # https://github.com/zammad/zammad/issues/2887
    context 'when clicking timepicker component' do
      # The y offset is 0 (i.e. the vertical center): the input is much shorter than
      # it is wide, so the original `y: 20` landed outside its box. Playwright
      # requires a click point to actually hit the target and kept retrying until it
      # timed out, while Chrome's Actions API tolerated the miss. The x offsets still
      # pick the left/right half of the field, which is what the widget reads.
      it 'in the first half, hours selected' do
        within :active_content do
          click_timepicker(offset_x: -10)
          wait.until { have_selection(0..2).matches?(find('.js-timepicker')) }
        end
      end

      it 'in the second half, minutes selected' do
        within :active_content do
          click_timepicker(offset_x: 10)
          wait.until { have_selection(3..5).matches?(find('.js-timepicker')) }
        end
      end
    end

    # The timepicker plugin rewrites the DOM once initialised, so don't cache the element.
    def click_timepicker(offset_x:)
      wait.until { page.evaluate_script("$('.content.active .js-timepicker').data('timepicker') !== undefined") }
      find('.js-timepicker').click(x: offset_x, y: 0)
    end

    matcher :have_selection do
      match { starts_at == expected.begin && ends_at == expected.end }

      def starts_at
        actual.evaluate_script 'this.selectionStart'
      end

      def ends_at
        actual.evaluate_script 'this.selectionEnd'
      end
    end
  end

  describe 'Basic sidebar handling because of regressions in #3757' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    before do
      visit "#ticket/zoom/#{ticket.id}"
      ensure_websocket
      wait_for_authenticated_session
    end

    it 'does show up the new priority' do
      high_prio = Ticket::Priority.find_by(name: '3 high')
      ticket.update(priority: high_prio)
      wait.until { page.find("select[name='priority_id']").value == high_prio.id.to_s }
      expect(page.find("select[name='priority_id']").value).to eq(high_prio.id.to_s)
    end

    it 'does show up the new group (different case because it will also trigger a full rerender because of potential permission changes)' do
      group = Group.find_by(name: 'some group1')
      ticket.update(group: group)
      wait.until { page.find("input[name='group_id']", visible: :all).value == group.id.to_s }
      expect(page.find("input[name='group_id']", visible: :all).value).to eq(group.id.to_s)
    end

    it 'does show up the new state and pending time' do
      pending_state = Ticket::State.find_by(name: 'pending reminder')
      ticket.update(state: pending_state, pending_time: 1.day.from_now)

      wait(30).until { page.find("select[name='state_id']").value == pending_state.id.to_s }
      expect(page.find("select[name='state_id']").value).to eq(pending_state.id.to_s)
      expect(page).to have_css("div[data-name='pending_time']")
    end

    it 'does merge attributes with remote priority (ajax) and local state (user)' do
      select 'closed', from: 'State'
      high_prio = Ticket::Priority.find_by(name: '3 high')
      closed_state = Ticket::State.find_by(name: 'closed')
      ticket.update(priority: high_prio)
      wait.until { page.find("select[name='priority_id']").value == high_prio.id.to_s }
      expect(page.find("select[name='priority_id']").value).to eq(high_prio.id.to_s)
      expect(page.find("select[name='state_id']").value).to eq(closed_state.id.to_s)
    end

    context 'when 2 users are in 2 different tickets' do
      let(:ticket2) { create(:ticket, group: Group.find_by(name: 'Users')) }
      let(:agent2)  { create(:agent, password: 'test', groups: [Group.find_by(name: 'Users')]) }

      before do
        using_session(:second_browser) do
          login(
            username: agent2.login,
            password: 'test',
          )
          visit "#ticket/zoom/#{ticket.id}"
          visit "#ticket/zoom/#{ticket2.id}"
        end
      end

      it 'does not make any changes to the second browser ticket' do
        closed_state = Ticket::State.find_by(name: 'closed')
        select 'closed', from: 'State'
        find('.js-submit').click
        using_session(:second_browser) do
          expect(page).to have_css(".tasks .task[data-key='Ticket-#{ticket.id}'] .icon-task-state.closed")
          expect(page.find(:active_content, "select[name='state_id']").value).not_to eq(closed_state.id.to_s)
        end
      end
    end
  end

  describe 'Make sidebar attachments unique #3930', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:article1) { create(:ticket_article, ticket: ticket) }
    let(:article2) { create(:ticket_article, ticket: ticket) }

    def attachment_add(article, filename)
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        "content #{filename}",
             filename:    filename,
             preferences: {
               'Content-Type' => 'text/plain',
             })
    end

    def authenticate
      attachment_add(article1, 'some_file.txt')
      attachment_add(article2, 'some_file.txt')
      attachment_add(article2, 'some_file2.txt')
      Setting.set('ui_ticket_zoom_sidebar_article_attachments', true)

      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
      page.find(".tabsSidebar-tabs .tabsSidebar-tab[data-tab='attachment']").click
    end

    it 'does show the attachment once' do
      expect(page).to have_css('.sidebar-content .attachment.attachment--preview', count: 2)
      expect(page).to have_css('.sidebar-content', text: 'some_file.txt')
      expect(page).to have_css('.sidebar-content', text: 'some_file2.txt')
    end

    it 'does show up new attachments' do
      page.find('.js-textarea').send_keys('new article with attachment')
      page.find('input#fileUpload_1', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
      expect(page).to have_text('mail001.box')
      wait.until { Taskbar.find_by(key: "Ticket-#{ticket.id}").attributes_with_association_ids['attachments'].present? }
      click '.js-submit'
      expect(page).to have_css('.sidebar-content', text: 'mail001.box')
    end
  end
end
