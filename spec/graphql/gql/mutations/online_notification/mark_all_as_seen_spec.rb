# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What marking all notifications as seen does is covered by spec/services/service/online_notification/mark_all_as_seen_spec.rb —
#   this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::OnlineNotification::MarkAllAsSeen, authenticated_as: :user, type: :graphql do
  let(:user) { create(:agent) }

  let(:query) do
    <<~QUERY
      mutation onlineNotificationMarkAllAsSeen {
        onlineNotificationMarkAllAsSeen {
          success
        }
      }
    QUERY
  end

  before do
    allow(Service::OnlineNotification::MarkAllAsSeen).to receive(:execute).and_call_original
    gql.execute(query)
  end

  it 'calls the MarkAllAsSeen service' do
    expect(Service::OnlineNotification::MarkAllAsSeen)
      .to have_received(:execute).with(current_user: user)
  end

  it 'returns success' do
    expect(gql.result.data).to include('success' => true)
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
