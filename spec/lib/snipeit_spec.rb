# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Snipeit do
  let(:token)    { 'some_token' }
  let(:endpoint) { 'https://snipeit.example.com/' }

  let(:hardware_response) do
    {
      id:           26,
      name:         'Laptop-001',
      asset_tag:    'LAP001',
      model:        { id: 1, name: 'MacBook Pro' },
      status_label: { id: 2, name: 'Ready to Deploy' },
    }.to_json
  end

  before do
    Setting.set('snipeit_integration', true)
    Setting.set('snipeit_config', { api_token: token, endpoint: endpoint, verify_ssl: false })
  end

  describe '.asset' do
    let!(:request_stub) do
      stub_request(:get, "#{endpoint}api/v1/hardware/26")
        .with(headers: { 'Authorization' => "Bearer #{token}" })
        .to_return(status: 200, body: hardware_response, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the raw asset with its nested attributes intact', aggregate_failures: true do
      asset = described_class.asset(26)

      expect(asset['id']).to eq(26)
      expect(asset.dig('model', 'name')).to eq('MacBook Pro')
    end

    it 'coerces the given id' do
      described_class.asset('26')

      expect(request_stub).to have_been_requested
    end

    # Snipe-IT has no bulk lookup by id, so the same ids get fetched over and over while a
    # ticket sidebar is open. Only the first lookup may hit the API.
    it 'issues a single request for repeated lookups of the same asset' do
      3.times { described_class.asset(26) }

      expect(request_stub).to have_been_requested.once
    end

    context 'when the asset does not exist' do
      let(:hardware_response) { { status: 'error', messages: 'Asset not found' }.to_json }

      it 'returns nil' do
        expect(described_class.asset(26)).to be_nil
      end

      # Otherwise an asset which was just created in Snipe-IT would keep reporting
      # 'not found' until the cache entry expires.
      it 'does not cache the miss' do
        2.times { described_class.asset(26) }

        expect(request_stub).to have_been_requested.twice
      end
    end
  end
end
