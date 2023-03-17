# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::OnlineNotifications, type: :graphql do
  context 'with a notification' do
    let(:user)                      { create(:agent) }
    let(:notification)              { create(:online_notification, user: user) }
    let(:another_user_notification) { create(:online_notification, user: create(:user)) }

    let(:query) do
      <<~QUERY
        query onlineNotifications {
          onlineNotifications {
            edges {
              node {
                id
              }
            }
          }
        }
      QUERY
    end

    before do
      user.groups << Ticket.first.group
      notification
      another_user_notification

      gql.execute(query)
    end

    it 'contains a notification', authenticated_as: :user do
      returned_ids = gql.result.nodes.pluck('id')

      expect(returned_ids).to contain_exactly(gql.id(notification))
    end
  end
end
