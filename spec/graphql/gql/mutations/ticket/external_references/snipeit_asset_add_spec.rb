# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::ExternalReferences::SnipeitAssetAdd, type: :graphql do
  let(:variables)                  { { ticketId: gql.id(ticket), snipeitAssetIds: snipeit_asset_ids } }
  let(:ticket)                     { create(:ticket, preferences: { snipeit: { asset_ids: [42] } }) }
  let(:snipeit_asset_ids)          { [26] }
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

  let(:mutation) do
    <<~MUTATION
      mutation ticketExternalReferencesSnipeitAssetAdd(
        $ticketId: ID
        $snipeitAssetIds: [Int!]!
      ) {
        ticketExternalReferencesSnipeitAssetAdd(
          ticketId: $ticketId
          snipeitAssetIds: $snipeitAssetIds
        ) {
          snipeitAssets {
            snipeitAssetId
            name
            assetTag
            serial
            model
            status
            category
            location
            link
          }
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  before do
    Setting.set('snipeit_integration', snipeit_integration_active)
    allow(Snipeit).to receive(:query).with('hardware/26').and_return(snipeit_api_asset)
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    context 'when snipeit integration is inactive' do
      let(:snipeit_integration_active) { false }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when ticket is used' do
      context 'when an agent has access to the ticket' do
        let(:agent) { create(:agent, groups: [ticket.group]) }

        context 'when the snipeit asset id already exists' do
          before do
            ticket.preferences[:snipeit] = { asset_ids: [26] }
            ticket.save!
          end

          it 'returns a user error' do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:errors].first).to include('field' => 'snipeit_asset_ids', 'message' => 'The Snipe-IT asset is already present on the ticket.')
          end
        end

        context 'when the snipeit asset id already exists as a string' do
          before do
            ticket.preferences[:snipeit] = { asset_ids: %w[26] }
            ticket.save!
          end

          it 'returns a user error' do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:errors].first).to include('field' => 'snipeit_asset_ids', 'message' => 'The Snipe-IT asset is already present on the ticket.')
          end
        end

        context 'when the same snipeit asset id is submitted twice' do
          let(:snipeit_asset_ids) { [26, 26] }

          it 'returns a user error', aggregate_failures: true do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:errors].first).to include('field' => 'snipeit_asset_ids', 'message' => 'The Snipe-IT asset is already present on the ticket.')
            expect(ticket.reload.preferences).to include(snipeit: { asset_ids: [42] })
          end
        end

        context 'when new snipeit asset should be added' do

          it 'returns the snipeit asset', aggregate_failures: true do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:snipeitAssets]).to contain_exactly(snipeit_asset)

            expect(ticket.reload.preferences)
              .to include(snipeit: { asset_ids: [42, 26] })
          end
        end
      end

      context 'when an agent has no access to the ticket' do
        before { gql.execute(mutation, variables:) }

        it_behaves_like 'graphql responds with error if unauthenticated'
      end
    end

    context 'without a ticket' do
      let(:variables) { { snipeitAssetIds: [26] } }

      context 'when new snipeit asset should be added' do

        it 'returns snipeit asset', aggregate_failures: true do
          gql.execute(mutation, variables: variables)

          expect(gql.result.data[:snipeitAssets]).to contain_exactly(snipeit_asset)
        end
      end
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(mutation, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
