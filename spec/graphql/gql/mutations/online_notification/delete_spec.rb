# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::OnlineNotification::Delete, authenticated_as: :user, type: :graphql do
  let(:user)                      { create(:agent) }
  let(:notification)              { create(:online_notification, user: user) }
  let(:another_user_notification) { create(:online_notification, user: create(:user)) }

  let(:query) do
    <<~QUERY
      mutation onlineNotificationDelete($onlineNotificationId: ID!) {
        onlineNotificationDelete(onlineNotificationId: $onlineNotificationId) {
          success
        }
      }
    QUERY
  end

  let(:variables) { { onlineNotificationId: notification_to_delete.to_gid_param } }

  before do
    gql.execute(query, variables: variables)
  end

  context 'when deleting a notification' do
    let(:notification_to_delete) { notification }

    it 'deletes notification' do
      expect(notification.class).not_to be_exist(notification.id)
    end
  end

  context 'when deleting inaccessible notification' do
    let(:notification_to_delete) { another_user_notification }

    it 'does not delete notification' do
      expect(notification.class).to be_exist(notification.id)
    end
  end
end
