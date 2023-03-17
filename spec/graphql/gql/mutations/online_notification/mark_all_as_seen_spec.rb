# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::OnlineNotification::MarkAllAsSeen, authenticated_as: :user, type: :graphql do
  let(:user)                      { create(:agent) }
  let(:notification_a)            { create(:online_notification, user: user) }
  let(:notification_b)            { create(:online_notification, user: user) }
  let(:notification_c)            { create(:online_notification, user: user) }
  let(:another_user_notification) { create(:online_notification, user: create(:user)) }
  let(:notifications_to_mark)     { [notification_a, notification_b] }

  let(:query) do
    <<~QUERY
      mutation onlineNotificationMarkAllAsSeen($onlineNotificationIds: [ID!]!) {
        onlineNotificationMarkAllAsSeen(onlineNotificationIds: $onlineNotificationIds) {
          onlineNotifications {
            id
          }
        }
      }
    QUERY
  end

  let(:variables) { { onlineNotificationIds: notifications_to_mark.map(&:to_gid_param) } }

  before do
    user.groups << Ticket.first.group
    notifications_to_mark   # Pre-create them to ignore trigger events from that.
    allow(Gql::Subscriptions::OnlineNotificationsCount).to receive(:trigger)
    gql.execute(query, variables: variables)
  end

  context 'when marking multiple notifications' do
    it 'marks selected notifications as seen' do
      expect([notification_a.reload, notification_b.reload])
        .to contain_exactly(
          have_attributes(id: notification_a.id, seen: true),
          have_attributes(id: notification_b.id, seen: true)
        )
    end

    it 'only calls trigger_subscriptions once' do
      expect(Gql::Subscriptions::OnlineNotificationsCount).to have_received(:trigger).once
    end

    it 'does not touch other notifications' do
      expect(notification_c.reload).to have_attributes(seen: false)
    end

    it 'returns touched notifications' do
      expect(gql.result.data['onlineNotifications'])
        .to contain_exactly(
          include('id' => gql.id(notification_a)),
          include('id' => gql.id(notification_b))
        )
    end
  end

  context 'when no notifications are selected' do
    let(:notifications_to_mark) { [] }

    it 'does not call trigger_subscriptions' do
      expect(Gql::Subscriptions::OnlineNotificationsCount).not_to have_received(:trigger)
    end

    it 'returns empty rexponse' do
      expect(gql.result.data['onlineNotifications']).to be_nil
    end
  end

  context 'when marking another user notifications' do
    let(:notifications_to_mark) { [another_user_notification] }

    it 'does not touch inaccessible notification' do
      expect(another_user_notification.reload).to have_attributes(seen: false)
    end

    it 'report as error' do
      expect(gql.result.error).to be_present
    end
  end

  context 'when marking non-existant user notifications' do
    let(:variables) { { onlineNotificationIds: ['asd'] } }

    it 'report as error' do
      expect(gql.result.error).to be_present
    end
  end
end
