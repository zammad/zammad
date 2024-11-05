# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::OnlineNotification::Seen, :aggregate_failures, type: :graphql do
  context 'when setting online notifications for different objects to seen' do
    let(:agent)               { create(:agent) }
    let(:notification)        { create(:online_notification, user: agent, o: object) }
    let(:other_notifications) { create_list(:online_notification, 5, user: create(:agent), o: object) }

    let(:user_with_permission)    { agent }
    let(:user_without_permission) { agent }

    let(:query) do
      <<~QUERY
        mutation onlineNotificationSeen($objectId: ID!) {
          onlineNotificationSeen(objectId: $objectId) {
            success
          }
        }
      QUERY
    end

    let(:variables) do
      {
        objectId: gql.id(object),
      }
    end

    shared_context 'when mobile: notification seen handling' do
      context 'with permissions', authenticated_as: :user_with_permission do
        before do
          object && notification && other_notifications

          if object.respond_to?(:group)
            agent.groups << object.group
          end

          gql.execute(query, variables: variables)
        end

        it 'marks the existing notification as seen' do
          expect(gql.result.data[:success]).to be true
          expect(notification.reload).to have_attributes(seen: true)
        end

        it 'does not mark other notifications for the same object as seen' do
          expect(other_notifications.map { |x| x.reload.seen }).to all(be(false))
        end
      end

      context 'without permission', authenticated_as: :user_without_permission do
        before do
          object && notification && other_notifications
          gql.execute(query, variables: variables)
        end

        it 'results in an error' do
          expect(gql.result.error_type).to eq Exceptions::Forbidden
          expect(gql.result.error_message).to match %r{not allowed to .*Policy#show\? this #{object.class.name}}
        end
      end
    end

    context 'with Ticket model' do
      let(:group)  { create(:group, email_address: nil) }
      let(:object) { create(:ticket, group: group) }

      include_context 'when mobile: notification seen handling'
    end

    context 'with User model' do
      let(:user_with_permission)    { agent }
      let(:user_without_permission) { create(:user) }
      let(:object)                  { create(:user) }

      include_context 'when mobile: notification seen handling'
    end

    context 'with Organization model' do
      let(:user_with_permission)    { agent }
      let(:user_without_permission) { create(:user) }
      let(:object)                  { create(:organization) }

      include_context 'when mobile: notification seen handling'
    end
  end
end
