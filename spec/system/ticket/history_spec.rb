# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket history', type: :system, authenticated_as: true, time_zone: 'Europe/London' do
  let(:group) { Group.find_by(name: 'Users') }
  let(:ticket) { create(:ticket, group: group) }
  let!(:session_user) { User.find_by(login: 'master@example.com') }

  before do
    freeze_time

    travel_to DateTime.parse('2021-01-22 13:40:00 UTC')
    current_time = Time.current
    ticket.update(title: 'New Ticket Title')
    ticket_article = create(:ticket_article, ticket: ticket, internal: true)
    ticket.update! state: Ticket::State.lookup(name: 'open')
    ticket.update! last_owner_update_at: current_time
    ticket.update! priority: Ticket::Priority.lookup(name: '1 low')
    ticket.update! last_contact_at: current_time
    ticket.update! last_contact_customer_at: current_time
    ticket.update! last_contact_agent_at: current_time
    ticket_article.update! internal: false

    travel_to DateTime.parse('2021-04-06 23:30:00 UTC')
    current_time = Time.current
    ticket.update! state: Ticket::State.lookup(name: 'pending close')
    ticket.update! priority: Ticket::Priority.lookup(name: '3 high')
    ticket_article.update! internal: true
    ticket.update! last_contact_at: current_time
    ticket.update! last_contact_customer_at: current_time
    ticket.update! last_contact_agent_at: current_time
    ticket.update! pending_time: current_time
    ticket.update! first_response_escalation_at: current_time

    travel_back

    session_user.preferences[:locale] = 'de-de'
    session_user.save!

    refresh

    visit "#ticket/zoom/#{ticket.id}"
    find('[data-tab="ticket"] .js-actions').click
    click('[data-type="ticket-history"]')
  end

  it "translates timestamp when attribute's tag is datetime" do
    expect(page).to have_css('li', text: %r{22.01.2021 13:40})
  end

  it 'does not include time with UTC format' do
    expect(page).to have_no_text(%r{ UTC})
  end

  it 'translates value when attribute is state' do
    expect(page).to have_css('li', text: %r{Ticket Status von 'neu'})
  end

  it 'translates value when attribute is priority' do
    expect(page).to have_css('li', text: %r{Ticket Priorität von '1 niedrig'})
  end

  it 'translates value when attribute is internal' do
    expect(page).to have_css('li', text: %r{Artikel intern von 'true'})
  end

  it 'translates last_contact_at display attribute' do
    expect(page).to have_css('li', text: %r{Ticket Letzter Kontakt von '22.01.2021 13:40' → '07.04.2021 00:30'})
  end

  it 'translates last_contact_customer_at display attribute' do
    expect(page).to have_css('li', text: %r{Ticket Letzter Kontakt \(Kunde\) von '22.01.2021 13:40' → '07.04.2021 00:30'})
  end

  it 'translates last_contact_agent_at display attribute' do
    expect(page).to have_css('li', text: %r{Ticket Letzter Kontakt \(Agent\) von '22.01.2021 13:40' → '07.04.2021 00:30'})
  end

  it 'translates pending_time display attribute' do
    expect(page).to have_css('li', text: %r{Ticket Warten bis '07.04.2021 00:30'})
  end
end
