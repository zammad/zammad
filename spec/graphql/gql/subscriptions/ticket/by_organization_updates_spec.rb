# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::Ticket::ByOrganizationUpdates, performs_jobs: true, type: :graphql do
  let(:subscription) do
    <<~SUBSCRIPTION
      subscription ticketByOrganizationUpdates($organizationId: ID!) {
        ticketByOrganizationUpdates(organizationId: $organizationId) {
          listChanged
        }
      }
    SUBSCRIPTION
  end

  let(:organization)    { create(:organization) }
  let(:filter_customer) { create(:customer, organization: organization) }
  let(:variables)       { { organizationId: gql.id(organization) } }
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

    it 'receives updates when a ticket for the organization changes' do
      mock_channel.mock_broadcasted_messages.clear

      create(:ticket, customer: filter_customer, organization: organization)

      perform_enqueued_jobs

      result = mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketByOrganizationUpdates')
      expect(result).to eq({ 'listChanged' => true })
    end
  end

  context 'with a customer', authenticated_as: :customer_user do
    let(:customer_user) { filter_customer }

    it_behaves_like 'requires agent permission'
  end
end
