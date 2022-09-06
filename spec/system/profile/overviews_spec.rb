# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Overviews', type: :system do
  def move_assigned_tickets_overview
    visit 'profile/overviews'
    overview_from = page.find('tr.item', text: 'My Assigned Tickets')
    overview_to = page.find('tr.item', text: 'Escalated Tickets')
    overview_from.drag_to overview_to
    wait.until { User::OverviewSorting.where(user: current_user)&.last&.overview_id == Overview.find_by(name: 'My Assigned Tickets').id }
  end

  def expect_user_ticket_overview
    visit 'ticket/view'
    overviews = page.all('.overview-header .js-tabsHolder span.tab-name', visible: :all).map { |e| e.text(:all) }
    expect(overviews.index('My Assigned Tickets')).to be > overviews.index('Escalated Tickets')
  end

  def expect_default_ticket_overview
    visit 'ticket/view'
    overviews = page.all('.overview-header .js-tabsHolder span.tab-name', visible: :all).map { |e| e.text(:all) }
    expect(overviews.index('My Assigned Tickets')).to be < overviews.index('Escalated Tickets')
  end

  def reset_overview_order
    visit 'profile/overviews'
    page.find('a[data-type=reset]').click
    wait.until { User::OverviewSorting.where(user: current_user).count.zero? }
  end

  it 'does provide drag and drop and reorder functionality' do

    # move "My Assigned Tickets" after "Escalated Tickets"
    move_assigned_tickets_overview

    # go to ticket overviews and verify
    expect_user_ticket_overview

    # go back and reset order
    reset_overview_order

    # go to ticket overviews and verify
    expect_default_ticket_overview
  end
end
