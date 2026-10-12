# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What deleting all notifications does is covered by spec/services/service/online_notification/delete_all_spec.rb —
#   this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::OnlineNotification::DeleteAll, authenticated_as: :user, type: :graphql do
  let(:user) { create(:agent) }

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
    allow(Service::OnlineNotification::DeleteAll).to receive(:execute).and_call_original
    gql.execute(query)
  end

  it 'calls the DeleteAll service' do
    expect(Service::OnlineNotification::DeleteAll)
      .to have_received(:execute).with(current_user: user)
  end

  it 'returns success' do
    expect(gql.result.data).to include('success' => true)
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
