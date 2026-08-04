# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_overview_level1_test.rb as a continuous
#   end-to-end scenario: paging through an overview from within the ticket zoom
#   (position counter and ticket number in sync) and the navigator reacting to a
#   ticket leaving the overview. Button mechanics and boundary states are covered
#   by 'previous/next clickability' in spec/system/ticket/zoom_spec.rb.
RSpec.describe 'Scenario > Overview navigator in the ticket zoom', authenticated_as: :authenticate, sessions_jobs: true, type: :system do
  let(:group)        { Group.find_by(name: 'Users') }
  let(:low_priority) { Ticket::Priority.find_by(name: '1 low') }

  let(:overview) do
    create(:overview,
           condition: {
             'ticket.priority_id' => { operator: 'is', value: [low_priority.id] },
           },
           order:     { by: 'created_at', direction: 'DESC' })
  end

  let(:tickets) do
    (1..3).map do |i|
      create(:ticket, group:, priority: low_priority, title: "overview navigator ##{i}")
    end
  end

  def authenticate
    tickets
    overview

    create(:agent, groups: [group])
  end

  def expect_position(position, ticket)
    within '.active .ticketZoom-controls .overview-navigator' do
      expect(page).to have_css('.pagination-counter .pagination-item-current', text: position.to_s)
    end

    expect(page).to have_css('.active .ticketZoom-header .ticket-number', text: ticket.number)
  end

  it 'pages through the overview and reacts to tickets leaving it' do
    visit "ticket/view/#{overview.link}"

    within(:active_content) do
      find('td', text: tickets.third.title).click
    end

    # Opened from the overview (DESC: newest first), the navigator starts at 1/3.
    expect_position(1, tickets.third)

    # Paging forward moves counter and ticket in sync.
    find('.active .overview-navigator .btn--split--last').click
    expect_position(2, tickets.second)

    find('.active .overview-navigator .btn--split--last').click
    expect_position(3, tickets.first)

    # Closing the current ticket does not remove it from this priority-based
    #   overview: the navigator stays consistent after the live update.
    tickets.first.update!(state: Ticket::State.lookup(name: 'closed'))

    expect_position(3, tickets.first)

    # Paging backward and forward again.
    find('.active .overview-navigator .btn--split--first').click
    expect_position(2, tickets.second)

    find('.active .overview-navigator .btn--split--last').click
    expect_position(3, tickets.first)

    # Once the ticket leaves the overview, the navigator disappears,
    #   but the ticket itself stays open.
    tickets.first.update!(priority: Ticket::Priority.find_by(name: '3 high'))

    expect(page).to have_no_css('.active .overview-navigator .pagination-counter .pagination-item-current', wait: 30)
    expect(page).to have_css('.active .ticketZoom-header .ticket-number', text: tickets.first.number)
  end
end
