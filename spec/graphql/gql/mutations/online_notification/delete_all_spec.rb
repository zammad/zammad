# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::OnlineNotification::DeleteAll, authenticated_as: :user, type: :graphql do
  let(:user)                      { create(:agent) }
  let(:notification)              { create(:online_notification, user: user) }
  let(:another_user_notification) { create(:online_notification, user: create(:user)) }

  let(:query) do
    <<~QUERY
      mutation onlineNotificationDeleteAll {
        onlineNotificationDeleteAll {
          success
        }
      }
    QUERY
  end

  before do
    notification
    another_user_notification
    allow(Service::OnlineNotification::DeleteAll).to receive(:execute).and_call_original
    gql.execute(query)
  end

  it 'calls the DeleteAll service' do
    expect(Service::OnlineNotification::DeleteAll)
      .to have_received(:execute).with(current_user: user)
  end

  it 'deletes all notifications for the current user' do
    expect(OnlineNotification.where(user: user)).to be_empty
  end

  it 'does not delete other users notifications' do
    expect(OnlineNotification).to exist(another_user_notification.id)
  end

  it 'returns success' do
    expect(gql.result.data).to include('success' => true)
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
