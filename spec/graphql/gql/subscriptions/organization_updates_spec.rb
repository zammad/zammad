# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::OrganizationUpdates, type: :graphql do
  let(:agent)        { create(:agent) }
  let(:organization) { create(:organization) }
  let(:variables)    { { organizationId: gql.id(organization) } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    gql.read_files(
      'apps/mobile/modules/organization/graphql/subscriptions/organizationUpdates.graphql',
      'apps/mobile/modules/organization/graphql/fragments/organizationAttributes.graphql',
      'shared/graphql/fragments/objectAttributeValues.graphql',
    )
  end

  before do
    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  shared_examples 'subscribes and receives updates' do
    it 'subscribes' do
      expect(gql.result.data).to eq({ 'organization' => nil })
    end

    it 'receives organization updates' do
      organization.save!

      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'organizationUpdates', 'organization', 'name')).to eq(organization.name)
    end
  end

  context 'with an agent', authenticated_as: :agent do
    context 'with permission' do
      include_examples 'subscribes and receives updates'

      context 'when losing permissions' do
        it 'receives no data anymore' do # rubocop:disable RSpec/ExampleLength
          agent.update!(roles: [])
          organization.save!

          expect(mock_channel.mock_broadcasted_messages.first[:result]).to include(
            {
              'data'   => nil,
              'errors' => include(
                include(
                  'message' => 'not allowed to show? this Organization',
                ),
              ),
            }
          )
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'with a customer', authenticated_as: :customer do
    let(:customer) { create(:customer, organization: organization) }

    include_examples 'subscribes and receives updates'

    context 'when losing permissions' do
      let(:customer) { create(:customer) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
