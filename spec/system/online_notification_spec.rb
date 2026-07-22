# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Online notification', type: :system do
  let(:session_user) { User.find_by(login: 'admin@example.com') }

  describe 'circle after pending reached' do
    around do |example|
      Ticket.without_callback :save, :before, :ticket_reset_pending_time_seconds do
        example.run
      end
    end

    context 'when pending time is reached soon' do
      before do
        visit "ticket/zoom/#{ticket.id}"

        find("a[data-key='Ticket-#{ticket.id}']")
      end

      # "loads as pending ticket" must observe this before the deadline passes, unlike
      #   "switches to open ticket" which can rely on have_css's own implicit wait to
      #   observe the transition - give it more real-time margin, especially for the
      #   nested "non-active tab" context below, which adds an extra page visit first.
      let(:ticket) { create(:ticket, owner: session_user, group: Group.first, state_name: 'pending reminder', pending_time: 10.seconds.from_now) }

      it 'loads as pending ticket' do
        expect(page).to have_css('.icon.pending')
      end

      it 'switches to open ticket' do
        expect(page).to have_css('.icon.open')
      end

      context 'when time is reached in non-active tab' do
        before { visit 'dashboard' }

        it 'loads as pending ticket' do
          expect(page).to have_css('.icon.pending')
        end

        it 'switches to open ticket' do
          expect(page).to have_css('.icon.open')
        end
      end
    end

    context 'when pending time is set to reached soon to an open ticket' do
      before do
        ensure_websocket do
          visit "ticket/zoom/#{ticket.id}"

          find("a[data-key='Ticket-#{ticket.id}']")
        end

        ticket.update! state: Ticket::State.lookup(name: 'pending reminder'), pending_time: 10.seconds.from_now
      end

      let(:ticket) { create(:ticket, owner: session_user, group: Group.first) }

      it 'loads as pending ticket' do
        expect(page).to have_css('.icon.pending')
      end

      it 'switches to open ticket' do
        expect(page).to have_css('.icon.open')
      end
    end
  end
end
