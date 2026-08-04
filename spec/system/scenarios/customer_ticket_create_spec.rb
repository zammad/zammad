# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/customer_ticket_create_test.rb as end-to-end scenarios:
#   the customer create mask without agent fields, the default follow-up state
#   reacting live to the article body in the customer zoom, agent ticket creation
#   right after a customer session and the customer_ticket_create channel toggle.
RSpec.describe 'Scenario > Customer ticket create', authenticated_as: :authenticate, authentication_type: :form, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:agent)    { create(:agent, password: 'test', groups: [group]) }
  let(:customer) { create(:customer, password: 'test') }

  let(:state_new)    { Ticket::State.find_by(name: 'new') }
  let(:state_open)   { Ticket::State.find_by(name: 'open') }
  let(:state_closed) { Ticket::State.find_by(name: 'closed') }

  def authenticate
    agent

    customer
  end

  def sidebar_state_value
    find('.sidebar select[name="state_id"]', visible: :all).value
  end

  def zoom_body
    find('.article-new [data-name="body"]')
  end

  # Customers have no taskbar, therefore no `.content.active` scope exists in their UI.
  it 'hides agent fields and drives the default follow-up state by the article body' do
    visit '#customer_ticket_new'

    within '.newTicket' do
      expect(page).to have_no_field('customer_id', type: 'hidden')
      expect(page).to have_no_css('[name="priority_id"]', visible: :all)

      find('[data-attribute-name="group_id"] .js-input').click
      click 'li', text: group.name

      find('[name="title"]').fill_in with: 'some subject 123äöü'
      find('[data-name="body"]').send_keys 'some body 123äöü'

      click '.js-submit'
    end

    # The created ticket opens in the zoom with the article and state "new".
    expect(page).to have_css('.ticketZoom div.ticket-article', text: 'some body 123äöü')
    expect(sidebar_state_value).to eq(state_new.id.to_s)

    # A customer follow-up does not change the state.
    zoom_body.send_keys 'some body 1234 äöüß'
    click '.js-submit'

    expect(page).to have_css('div.ticket-article', text: 'some body 1234 äöüß')
    expect(sidebar_state_value).to eq(state_new.id.to_s)

    # Closing the ticket...
    find('.sidebar select[name="state_id"]').select('closed')
    zoom_body.send_keys 'close #1'
    click '.js-submit'

    expect(page).to have_css('div.ticket-article', text: 'close #1')
    expect(sidebar_state_value).to eq(state_closed.id.to_s)

    # ...typing into the body switches the default follow-up state to open live...
    zoom_body.send_keys 'some body blublub'
    wait.until { sidebar_state_value == state_open.id.to_s }

    # ...emptying the body switches it back...
    zoom_body.send_keys([magic_key, 'a'], :backspace)
    wait.until { sidebar_state_value == state_closed.id.to_s }

    # ...and submitting with a body persists the open state.
    zoom_body.send_keys 'some body blublub blub'
    wait.until { sidebar_state_value == state_open.id.to_s }

    click '.js-submit'

    expect(page).to have_css('div.ticket-article', text: 'some body blublub blub')
    expect(sidebar_state_value).to eq(state_open.id.to_s)
  end

  it 'allows agent ticket creation right after a customer session' do
    visit '#customer_ticket_new'

    within '.newTicket' do
      find('[data-attribute-name="group_id"] .js-input').click
      click 'li', text: group.name

      find('[name="title"]').fill_in with: 'relogin - customer - agent - test 1'
      find('[data-name="body"]').send_keys 'relogin - customer - agent - test 1'

      click '.js-submit'
    end

    expect(page).to have_css('.ticketZoom div.ticket-article', text: 'relogin - customer - agent - test 1')

    # The agent create flow works right after the customer session.
    logout
    login(username: agent.login, password: 'test')

    visit '#ticket/create'

    within(:active_content) do
      find('[name=customer_id_completion]').fill_in with: customer.email

      expect(page).to have_css('.recipientList-entry.js-object')
      first('.recipientList-entry.js-object').click

      find('[name="title"]').fill_in with: 'relogin - customer - agent - test 2'
      find('[data-name="body"]').send_keys 'relogin - customer - agent - test 2'

      click '.js-submit'
    end

    expect(page).to have_css('.content.active .ticketZoom-header .ticket-number', text: %r{\d})
    expect(Ticket.exists?(title: 'relogin - customer - agent - test 2')).to be(true)
  end

  it 'hides the ticket creation for customers when the web channel setting is off' do
    Setting.set('customer_ticket_create', false)

    logout
    login(username: customer.email, password: 'test')

    expect(page).to have_no_link(href: '#customer_ticket_new')

    Setting.set('customer_ticket_create', true)

    logout
    login(username: customer.email, password: 'test')

    expect(page).to have_link(href: '#customer_ticket_new')
  end
end
