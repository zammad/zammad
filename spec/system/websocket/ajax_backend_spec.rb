# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The legacy frontend falls back to AJAX long polling when no websocket connection
#   is possible, and the setting 'websocket_backend' can select it right away.
RSpec.describe 'WebSocket > AJAX long polling backend', type: :system do
  let(:admin) { User.find_by(login: 'admin@example.com') }

  before do
    Setting.set('websocket_backend', 'ajax')
  end

  def ajax_session_of(user)
    Sessions.list.values.find do |session|
      session.dig(:meta, :type) == 'ajax' && session.dig(:user, 'id').to_i == user.id
    end
  end

  it 'boots the app and logs in over the ajax channel' do
    visit 'ticket/view/my_assigned'

    expect(page).to have_css('.content.active .page-header-title', text: 'My Assigned Tickets')

    ensure_websocket
    expect(page.evaluate_script('App.WebSocket.channel()')).to eq('ajax')

    wait.until { ajax_session_of(admin) }
  end

  # The setting has to be in place before the login page is loaded.
  context 'when logging in via the form', authenticated_as: false do
    it 'logs in over the ajax channel' do
      login(username: 'admin@example.com', password: 'test')

      ensure_websocket
      expect(page.evaluate_script('App.WebSocket.channel()')).to eq('ajax')

      wait.until { ajax_session_of(admin) }
    end
  end

  context 'when a ticket is updated' do
    let(:ticket)    { create(:ticket, group: Group.first, title: 'Ajax ticket') }
    let(:new_title) { 'Ajax ticket renamed' }

    it 'pushes the update to the ticket zoom' do
      visit "ticket/zoom/#{ticket.id}"

      expect(page).to have_css('.ticketZoom-header .ticket-title', text: ticket.title)
      ensure_websocket

      ticket.update!(title: new_title)

      expect(page).to have_css('.ticketZoom-header .ticket-title', text: new_title)
    end

    # Core Workflow requests stay on the REST endpoint, long polling would delay every response.
    it 'applies a Core Workflow in the ticket zoom form' do
      visit "ticket/zoom/#{ticket.id}"

      ensure_websocket
      expect(page.evaluate_script('App.FormHandlerCoreWorkflow.useWebSockets()')).to be_falsey
      expect(page).to have_no_css('.content.active .sidebar [data-name="pending_time"]', visible: :visible)

      within('.content.active .sidebar') do
        select 'pending reminder', from: 'state_id'
      end

      expect(page).to have_css('.content.active .sidebar [data-name="pending_time"]', visible: :visible)
    end

    it 'pushes the update to the overview', sessions_jobs: true do
      ticket
      visit 'ticket/view/all_open'

      expect(page).to have_css('.content.active .js-tableBody', text: ticket.title)
      ensure_websocket

      ticket.update!(title: new_title)

      expect(page).to have_css('.content.active .js-tableBody', text: new_title)
    end
  end
end
