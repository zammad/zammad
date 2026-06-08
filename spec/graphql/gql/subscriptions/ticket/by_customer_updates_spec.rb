# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::Ticket::ByCustomerUpdates, performs_jobs: true, type: :graphql do
  let(:subscription) do
    <<~SUBSCRIPTION
      subscription ticketByCustomerUpdates($customerId: ID!) {
        ticketByCustomerUpdates(customerId: $customerId) {
          listChanged
        }
      }
    SUBSCRIPTION
  end

  let(:filter_customer) { create(:customer) }
  let(:variables)       { { customerId: gql.id(filter_customer) } }
  let(:mock_channel)    { build_mock_channel }

  shared_examples 'requires agent permission' do
    it 'rejects subscription' do
      gql.execute(subscription, variables: variables, context: { channel: mock_channel })

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'with an agent', authenticated_as: :agent_user do
    let(:agent_user) { create(:agent) }

    before do
      gql.execute(subscription, variables: variables, context: { channel: mock_channel })
    end

    it 'subscribes' do
      expect(gql.result.data).to eq({ 'listChanged' => nil })
    end

    it 'receives updates when a matching ticket changes' do
      mock_channel.mock_broadcasted_messages.clear

      create(:ticket, customer: filter_customer)

      perform_enqueued_jobs

      result = mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketByCustomerUpdates')
      expect(result).to eq({ 'listChanged' => true })
    end
  end

  context 'with a customer', authenticated_as: :customer_user do
    let(:customer_user) { create(:customer) }

    it_behaves_like 'requires agent permission'
  end
end
