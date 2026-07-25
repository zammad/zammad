# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::ExternalReferences::SnipeitAssetList, type: :graphql do
  let(:variables) { { ticketId: gql.id(ticket) } }
  let(:ticket)    { create(:ticket, preferences: { snipeit: { asset_ids: [26] } }) }

  let(:query) do
    <<~QUERY
      query ticketExternalReferencesSnipeitAssetList(
        $ticketId: ID
        $snipeitAssetIds: [Int!]
      ) {
        ticketExternalReferencesSnipeitAssetList(
          input: {
            ticketId: $ticketId
            snipeitAssetIds: $snipeitAssetIds
          }
        ) {
          snipeitAssetId
          name
          link
          model
          status
          category
          location
          assetTag
          serial
        }
      }
    QUERY
  end

  let(:snipeit_api_asset) do
    {
      'id'           => 26,
      'name'         => 'Laptop-001',
      'asset_tag'    => 'LAP001',
      'serial'       => 'ABC123',
      'link'         => 'http://snipeit.example/hardware/26',
      'model'        => { 'name' => 'MacBook Pro' },
      'status_label' => { 'name' => 'Ready to Deploy' },
      'category'     => { 'name' => 'Laptops' },
      'location'     => { 'name' => 'HQ' },
    }
  end
  let(:snipeit_asset) do
    {
      'snipeitAssetId' => 26,
      'name'           => 'Laptop-001',
      'assetTag'       => 'LAP001',
      'serial'         => 'ABC123',
      'link'           => 'http://snipeit.example/hardware/26',
      'model'          => 'MacBook Pro',
      'status'         => 'Ready to Deploy',
      'category'       => 'Laptops',
      'location'       => 'HQ',
    }
  end
  let(:snipeit_integration_active) { true }

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [ticket.group]) }

    before do
      Setting.set('snipeit_integration', snipeit_integration_active)
      allow(Snipeit).to receive(:query).with('hardware/26').and_return(snipeit_api_asset)
      gql.execute(query, variables: variables)
    end

    context 'when snipeit integration is inactive' do
      let(:snipeit_integration_active) { false }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when ticket is used' do
      it 'returns snipeit assets', aggregate_failures: true do
        expect(gql.result.data).to eq([snipeit_asset])
      end
    end

    context 'when snipeit asset ids are used' do
      let(:variables) { { snipeitAssetIds: [26] } }

      it 'returns snipeit assets', aggregate_failures: true do
        expect(gql.result.data).to eq([snipeit_asset])
      end
    end

    context 'when no input is provided' do
      let(:variables) { {} }

      it 'returns a validation error', aggregate_failures: true do
        expect(gql.result.error_type).to eq(GraphQL::Schema::Validator::ValidationFailedError)
      end
    end
  end

  context 'when unauthenticated' do
    before do
      Setting.set('snipeit_integration', true)
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
