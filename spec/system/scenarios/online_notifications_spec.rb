# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_online_notification_test.rb as a continuous
#   end-to-end scenario for the legacy notifications widget: empty state, live arrival,
#   read state of single notifications, mark-all, the mixed read/unread counts and
#   clear-all including its confirmation dialog.
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

    # Empty state: no unread notifications, mark-all and clear-all buttons hidden,
    #   no counter digit.
    open_notifications

    expect(page).to have_css('.js-noNotifications', text: 'No unread notifications')
    expect(page).to have_css('.js-mark.hide', visible: :all)
    expect(page).to have_css('.js-clear.hide', visible: :all)
    expect(page).to have_no_css('.js-notificationsCounter', text: %r{\d})

    # A new notification arrives live in the already open widget.
    notify('online notification #1')

    expect(page).to have_css('.js-notificationsContainer .js-item', text: 'online notification #1')
    expect(page).to have_css('.js-notificationsCounter', text: '1')
    expect(page).to have_css('.js-mark', text: 'Mark all as read', visible: :visible)
    expect(page).to have_css('.js-clear', text: 'Clear all', visible: :visible)

    # A second notification arrives.
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

    # A new notification after mark-all: read items stay listed.
    notify('online notification #4')

    expect(page).to have_css('.js-notificationsCounter', text: '1')
    expect(page).to have_css('.js-notificationsContainer .js-item', count: 4)
    expect(page).to have_css('.js-notificationsContainer .js-item.is-inactive', count: 3)

    # Newest notification is listed first.
    expect(first('.js-notificationsContainer .js-item')).to have_text('online notification #4')

    # Clear all closes the widget and asks for confirmation first.
    find('.js-clear').click

    expect(page).to have_no_css('.js-notificationsContainer.is-visible')

    in_modal disappears: true do
      expect(page).to have_css('.modal-header', text: 'Clear all notifications')
      expect(page).to have_css('.modal-body', text: 'All notifications will be deleted. This action cannot be undone.')
      expect(page).to have_css('.js-submit.btn--danger', text: 'Delete all')

      find('.js-cancel').click
    end

    # Cancelling reopens the widget and keeps all notifications untouched.
    expect(page).to have_css('.js-notificationsContainer.is-visible')
    expect(page).to have_css('.js-notificationsContainer .js-item', count: 4)
    expect(page).to have_css('.js-notificationsCounter', text: '1')
    expect(OnlineNotification.where(user: agent).count).to eq(4)

    # Confirming deletes all notifications and leaves the widget closed.
    find('.js-clear').click

    in_modal do
      find('.js-submit').click
    end

    expect(page).to have_no_css('.js-notificationsContainer.is-visible')
    expect(OnlineNotification.where(user: agent)).to be_empty

    # Back to the empty state: no items, no counter digit, clear-all hidden again.
    open_notifications

    expect(page).to have_css('.js-noNotifications', text: 'No unread notifications')
    expect(page).to have_no_css('.js-notificationsContainer .js-item')
    expect(page).to have_css('.js-mark.hide', visible: :all)
    expect(page).to have_css('.js-clear.hide', visible: :all)
    expect(page).to have_no_css('.js-notificationsCounter', text: %r{\d})
  end
end
