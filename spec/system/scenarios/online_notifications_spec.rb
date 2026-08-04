# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_online_notification_test.rb as a continuous
#   end-to-end scenario for the legacy notifications widget: empty state, live arrival,
#   read state of single notifications, mark-all and the mixed read/unread counts.
RSpec.describe 'Scenario > Online notifications widget', authenticated_as: :agent, performs_jobs: true, type: :system do
  let(:group)         { Group.find_by(name: 'Users') }
  let(:agent)         { create(:agent, groups: [group]) }
  let(:another_agent) { create(:agent, groups: [group]) }

  # Another agent creates a ticket, the transaction backend generates the
  #   online notification and pushes it into the widget live.
  def notify(title)
    UserInfo.with_user_id(another_agent.id) do
      create(:ticket, group:, title: title)
    end

    perform_enqueued_jobs commit_transaction: true
  end

  def open_notifications
    find('.js-toggleNotifications').click
  end

  it 'counts, lists and marks notifications correctly' do
    visit 'dashboard'

    # Empty state: no unread notifications, mark-all button hidden, no counter digit.
    open_notifications

    expect(page).to have_css('.js-noNotifications', text: 'No unread notifications')
    expect(page).to have_css('.js-mark.hide', visible: :all)
    expect(page).to have_no_css('.js-notificationsCounter', text: %r{\d})

    # A new notification arrives live: item appears, counter shows 1, mark-all appears.
    notify('online notification #1')

    expect(page).to have_css('.js-notificationsContainer .js-item', text: 'online notification #1')
    expect(page).to have_css('.js-notificationsCounter', text: '1')
    expect(page).to have_no_css('.js-mark.hide', visible: :all)

    # A second notification: counter shows 2, both items listed.
    notify('online notification #2')

    expect(page).to have_css('.js-notificationsCounter', text: '2')
    expect(page).to have_css('.js-notificationsContainer .js-item', count: 2)

    # Opening a notification marks it as read: counter decrements,
    #   the item stays in the list as inactive.
    first('.js-notificationsContainer .js-item').click

    expect(page).to have_css('.content.active .ticketZoom')

    open_notifications

    expect(page).to have_css('.js-notificationsCounter', text: '1')
    expect(page).to have_css('.js-notificationsContainer .js-item', count: 2)
    expect(page).to have_css('.js-notificationsContainer .js-item.is-inactive', count: 1)

    # Another notification in the mixed state: counter goes up again,
    #   the read notification stays inactive.
    notify('online notification #3')

    expect(page).to have_css('.js-notificationsCounter', text: '2')
    expect(page).to have_css('.js-notificationsContainer .js-item', count: 3)
    expect(page).to have_css('.js-notificationsContainer .js-item.is-inactive', count: 1)

    # Mark all as read: all items stay listed as inactive, counter empties.
    find('.js-mark').click

    expect(page).to have_css('.js-notificationsContainer .js-item.is-inactive', count: 3)
    expect(page).to have_no_css('.js-notificationsCounter', text: %r{\d})

    # A notification after mark-all: counter restarts at 1, read items stay inactive.
    notify('online notification #4')

    expect(page).to have_css('.js-notificationsCounter', text: '1')
    expect(page).to have_css('.js-notificationsContainer .js-item', count: 4)
    expect(page).to have_css('.js-notificationsContainer .js-item.is-inactive', count: 3)

    # Newest notification is listed first.
    expect(first('.js-notificationsContainer .js-item')).to have_text('online notification #4')
  end
end
