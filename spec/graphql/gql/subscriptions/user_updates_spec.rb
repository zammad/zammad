# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::UserUpdates, type: :graphql do

  let(:subscription) do
    <<~QUERY
      subscription userUpdates($userId: ID!) {
        userUpdates(userId: $userId) {
          user {
            id
            firstname
            lastname
          }
        }
      }
    QUERY
  end
  let(:mock_channel) { build_mock_channel }
  let(:target)       { create(:user) }
  let(:variables)    { { userId: gql.id(target) } }

  before do
    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  context 'with authenticated user', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'subscribes' do
      expect(gql.result.data).to eq({ 'user' => nil })
    end

    it 'receives user updates for target user' do
      target.save!
      expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['userUpdates']['user']['firstname']).to eq(target.firstname)
    end

    it 'does not receive user updates for other users' do
      create(:agent).save!
      expect(mock_channel.mock_broadcasted_messages).to be_empty
    end
  end

  context 'with authenticated customer', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    context 'when subscribing for other users' do
      it 'does not subscribe but returns an authorization error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when subscribing for itself' do
      let(:target) { customer }

      it 'subscribes' do
        expect(gql.result.data).to eq({ 'user' => nil })
      end

      it 'receives user updates for target user' do
        target.save!
        expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['userUpdates']['user']['firstname']).to eq(target.firstname)
      end

      it 'does not receive user updates for other users' do
        create(:agent).save!
        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
