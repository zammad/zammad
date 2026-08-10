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

  let(:group_a)         { create(:group) }
  let(:group_b)         { create(:group) }
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
    let(:agent_user) { create(:agent, groups: [group_a]) }

    context 'when the organization has no tickets' do
      before do
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })
      end

      it 'subscribes' do
        expect(gql.result.data).to eq({ 'listChanged' => nil })
      end

      it 'receives updates when a ticket is created in an accessible group' do
        mock_channel.mock_broadcasted_messages.clear

        create(:ticket, customer: filter_customer, organization: organization, group: group_a)

        perform_enqueued_jobs

        result = mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketByOrganizationUpdates')
        expect(result).to eq({ 'listChanged' => true })
      end

      it 'does not receive updates when a ticket is created in an inaccessible group' do
        mock_channel.mock_broadcasted_messages.clear

        create(:ticket, customer: filter_customer, organization: organization, group: group_b)

        perform_enqueued_jobs

        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end

    context 'when the organization has tickets only in groups the agent can access' do
      before do
        create(:ticket, customer: filter_customer, organization: organization, group: group_a)
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })
      end

      it 'subscribes' do
        expect(gql.result.data).to eq({ 'listChanged' => nil })
      end

      it 'receives updates when a matching ticket changes' do
        mock_channel.mock_broadcasted_messages.clear

        create(:ticket, customer: filter_customer, organization: organization, group: group_a)

        perform_enqueued_jobs

        result = mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketByOrganizationUpdates')
        expect(result).to eq({ 'listChanged' => true })
      end
    end

    context 'when the organization has tickets only in groups the agent cannot access' do
      before do
        create(:ticket, customer: filter_customer, organization: organization, group: group_b)
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })
      end

      it 'subscribes' do
        expect(gql.result.data).to eq({ 'listChanged' => nil })
      end

      it 'does not receive updates for inaccessible group tickets' do
        mock_channel.mock_broadcasted_messages.clear

        create(:ticket, customer: filter_customer, organization: organization, group: group_b)

        perform_enqueued_jobs

        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end

    context 'when the organization has tickets only in inaccessible groups, but is shared and the agent belongs to it' do
      let(:organization) { create(:organization, shared: true) }
      let(:agent_user)   { create(:agent_and_customer, groups: [group_a], organization: organization) }

      before do
        create(:ticket, customer: filter_customer, organization: organization, group: group_b)
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })
      end

      it 'receives updates for tickets readable via the shared organization' do
        mock_channel.mock_broadcasted_messages.clear

        create(:ticket, customer: filter_customer, organization: organization, group: group_b)

        perform_enqueued_jobs

        result = mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketByOrganizationUpdates')
        expect(result).to eq({ 'listChanged' => true })
      end
    end

    context 'when the organization has tickets in both accessible and inaccessible groups' do
      before do
        create(:ticket, customer: filter_customer, organization: organization, group: group_a)
        create(:ticket, customer: filter_customer, organization: organization, group: group_b)
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })
      end

      it 'subscribes' do
        expect(gql.result.data).to eq({ 'listChanged' => nil })
      end

      it 'receives updates when at least one ticket is in an accessible group' do
        mock_channel.mock_broadcasted_messages.clear

        create(:ticket, customer: filter_customer, organization: organization, group: group_a)

        perform_enqueued_jobs

        result = mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'ticketByOrganizationUpdates')
        expect(result).to eq({ 'listChanged' => true })
      end
    end
  end

  context 'with a customer', authenticated_as: :customer_user do
    let(:customer_user) { filter_customer }

    it_behaves_like 'requires agent permission'
  end
end
