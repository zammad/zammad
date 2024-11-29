# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Online Notifications', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:agent_b)  { create(:agent, groups: [group]) }
  let(:ticket)   { create(:ticket, group:, title: 'Ticket A') }
  let(:ticket_b) { create(:ticket, group:, title: 'Ticket B') }

  let(:online_notification)            { create(:online_notification, user: agent, created_by: agent_b, updated_by: agent_b, o: ticket, type_name: 'update') }
  let(:online_notification_new_ticket) { create(:online_notification, user: agent, created_by: agent_b, updated_by: agent_b, o: ticket_b, type_name: 'create') }

  context 'when receiving a new ticket notification' do
    before do
      online_notification

      visit '/'

      # Initial subscription request will fetch the new online notification,
      #   which is why we must wait for the update flag instead of the start.
      wait_for_subscription_update('onlineNotificationsCount', number: 1)
    end

    it 'receives an online notification' do
      expect(find('[aria-label="Unseen notifications count"]')).to have_text('1')

      find('button[aria-label="Show notifications"]').click

      within('[role="region"]') do
        expect(page).to have_text("#{agent_b.fullname} updated ticket Ticket A")
        click_on 'mark all as read'
        wait_for_mutation('onlineNotificationMarkAllAsSeen')
      end

      find('button[aria-label="Show notifications"]').click

      within('[role="region"]') do
        expect(page).to have_css('a', text: "#{agent_b.fullname} updated ticket Ticket A", style: { opacity: '0.3' })
      end

      find("[aria-label='#{Capybara::Selector::CSS.escape(agent.fullname)}']").click

      click_on 'Profile settings'

      click_on 'Notifications'

      find('label', text: 'New ticket - All tickets').click
      find('label', text: 'Ticket update - All tickets').click

      click_on 'Save Notifications'

      wait_for_mutation('userCurrentNotificationPreferencesUpdate', number: 1)

      expect(agent.preferences['notification_config']['matrix']).to include(
        'create'           => include(
          'criteria' => include('owned_by_me' => true, 'owned_by_nobody' => true, 'subscribed' => true, 'no' => false),
          'channel'  => include('email' => true, 'online' => true)
        ),
        'update'           => include(
          'criteria' => include('owned_by_me' => true, 'owned_by_nobody' => true, 'subscribed' => true, 'no' => false),
          'channel'  => include('email' => true, 'online' => true)
        ),
        'reminder_reached' => include(
          'criteria' => include('owned_by_me' => true, 'owned_by_nobody' => false, 'subscribed' => false, 'no' => false),
          'channel'  => include('email' => true, 'online' => true)
        ),
        'escalation'       => include(
          'criteria' => include('owned_by_me' => true, 'owned_by_nobody' => false, 'subscribed' => false, 'no' => false),
          'channel'  => include('email' => true, 'online' => true)
        )
      )

      online_notification_new_ticket

      wait_for_subscription_update('onlineNotificationsCount', number: 2)

      expect(find('[aria-label="Unseen notifications count"]')).to have_text('1')

      find('button[aria-label="Show notifications"]').click

      within('[role="region"]') do
        click_on "#{agent_b.fullname} created ticket Ticket B"
      end

      wait_for_mutation('onlineNotificationSeen')
      wait_for_subscription_update('onlineNotificationsCount', number: 3)

      expect(page).to have_current_path("/desktop/tickets/#{ticket_b.id}")

      find('button[aria-label="Show notifications"]').click

      within('[role="region"]') do
        expect(page).to have_css('a', text: "#{agent_b.fullname} created ticket Ticket B", style: { opacity: '0.3' })
      end
    end
  end
end
