# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Navigation', type: :system do
  # https://github.com/zammad/zammad/issues/3260
  describe 'next in overview macro changes URL', authenticated_as: :authenticate do
    let(:next_ticket) { create(:ticket, title: 'next Ticket', group: Group.first) }
    let(:macro)       { create(:macro, name: 'next macro', ux_flow_next_up: 'next_from_overview') }

    def authenticate
      next_ticket && macro

      true
    end

    it 'to next Ticket ID' do
      visit 'ticket/view/all_unassigned'
      click_on 'Help me! I am an example ticket 🎓'
      click '.js-openDropdownMacro'
      find(:macro, macro.id).click

      expect(page).to have_current_path(%r{ticket/zoom/#{next_ticket.id}$}, url: true)
    end
  end

  # https://github.com/zammad/zammad/issues/3279
  describe 'previous/next clickability when at last or first ticket' do
    let(:ticket_a) { create(:ticket, title: 'ticket a', group: Group.first) }
    let(:ticket_b) { create(:ticket, title: 'ticket b', group: Group.first) }

    before do
      ticket_a && ticket_b

      visit 'ticket/view/all_unassigned'
    end

    # ticket_zoom.jst.eco renders the pagination navigator twice - once for the
    #   always-visible header (.ticketZoom-controls) and once for the sticky
    #   scroll header (.scrollPageHeader), which is only revealed on scroll via a
    #   CSS transform. Playwright's bounding-box visibility check does not
    #   filter the latter out, so a bare '.pagination .btn--split--last'
    #   selector is ambiguous. Scope to the always-visible header instead.
    it 'previous is not clickable for the first item' do
      open_nth_item(0)

      expect(page).to have_css('.ticketZoom-controls .pagination .btn--split--first.is-disabled')
    end

    it 'next is clickable for the first item' do
      open_nth_item(0)

      expect { click '.ticketZoom-controls .pagination .btn--split--last' }.to change { page.find('.content.active')[:id] }
    end

    it 'previous is clickable for the middle item' do
      open_nth_item(1)

      expect { click '.ticketZoom-controls .pagination .btn--split--first' }.to change { page.find('.content.active')[:id] }
    end

    it 'next is clickable for the middle item' do
      open_nth_item(1)

      expect { click '.ticketZoom-controls .pagination .btn--split--last' }.to change { page.find('.content.active')[:id] }
    end

    it 'previous is clickable for the last item' do
      open_nth_item(2)

      expect { click '.ticketZoom-controls .pagination .btn--split--first' }.to change { page.find('.content.active')[:id] }
    end

    it 'next is not clickable for the last item' do
      open_nth_item(2)

      expect(page).to have_css('.ticketZoom-controls .pagination .btn--split--last.is-disabled')
    end

    def open_nth_item(nth)
      within :active_content do
        find_all('.table tr.item a[href^="#ticket/zoom"]')[nth].click
      end

      await_empty_ajax_queue
    end
  end

  # https://github.com/zammad/zammad/issues/3267
  describe 'previous/next buttons are added when open ticket is opened from overview' do
    let(:ticket_a) { create(:ticket, title: 'ticket a', group: Group.first) }
    let(:ticket_b) { create(:ticket, title: 'ticket b', group: Group.first) }

    # prepare an opened ticket and go to overview
    before do
      ticket_a && ticket_b

      visit "ticket/zoom/#{ticket_a.id}"

      visit 'ticket/view/all_unassigned'
    end

    it 'adds previous/next buttons to existing ticket' do
      within :active_content do
        click_on ticket_a.title

        expect(page).to have_css('.pagination-counter')
      end
    end

    it 'keeps previous/next buttons when navigating to overview ticket from elsewhere' do
      within :active_content do
        click_on ticket_a.title
        visit 'dashboard'
        visit "ticket/zoom/#{ticket_a.id}"

        expect(page).to have_css('.pagination-counter')
      end
    end
  end

  describe 'Allow additional usage of Ticket Number in (Zoom) URL #849' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    it 'does find the ticket by ticket number' do
      visit "#ticket/zoom/number/#{ticket.number}"
      expect(current_url).to include("ticket/zoom/#{ticket.id}")
    end

    it 'does fail properly for ticket numbers which are not found' do
      visit '#ticket/zoom/number/123456789'
      expect(page).to have_text('The requested Ticket could not be found.')
    end
  end
end
