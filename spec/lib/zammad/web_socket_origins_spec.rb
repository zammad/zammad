# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::WebSocketOrigins do
  describe '.configured' do
    let(:alternative_fqdn) { 'tenant.example.org' }

    before do
      allow(Setting).to receive(:get).and_call_original
      allow(Setting).to receive(:get).with('http_type').and_return('https')
      allow(Setting).to receive(:get).with('fqdn').and_return('support.example.org')
      allow(Setting).to receive(:get).with('alternative_fqdn').and_return(alternative_fqdn)
    end

    it 'returns the canonical and the alternative origin' do
      expect(described_class.configured).to eq(['https://support.example.org', 'https://tenant.example.org'])
    end

    [nil, '', ' '].each do |value|
      context "with alternative_fqdn set to #{value.inspect}" do
        let(:alternative_fqdn) { value }

        it 'returns only the canonical origin' do
          expect(described_class.configured).to eq(['https://support.example.org'])
        end
      end
    end
  end
end
