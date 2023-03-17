# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::OnlineNotifications, authenticated_as: :user, type: :graphql do
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
                createdAt
                createdBy {
                  id
                  email
                }
                typeName
                objectName
                metaObject {
                  ... on Ticket {
                    id
                    title
                  }
                }
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
    end

    it 'contains a notification' do
      gql.execute(query)

      returned_ids = gql.result.nodes.pluck('id')

      expect(returned_ids).to contain_exactly(gql.id(notification))
    end

    it 'returns meta object' do
      gql.execute(query)

      expect(gql.result.nodes)
        .to include(include('id' => gql.id(notification), 'metaObject' => include('id' => gql.id(Ticket.first))))
    end

    context 'with notification pointing to inaccessible ticket' do
      let(:inaccessible_ticket) { create(:ticket) }
      let(:inaccessible_notification) { create(:online_notification, user: user, o: inaccessible_ticket) }

      before do
        inaccessible_notification
      end

      it 'returns list' do
        gql.execute(query)

        returned_ids = gql.result.nodes.pluck('id')

        expect(returned_ids).to contain_exactly(gql.id(notification), gql.id(inaccessible_notification))
      end

      it 'returns inaccessible notification with no meta object' do
        gql.execute(query)

        expect(gql.result.nodes)
          .to include(include('id' => gql.id(inaccessible_notification), 'metaObject' => nil, 'createdBy' => nil))
      end
    end
  end
end
