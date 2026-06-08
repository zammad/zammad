# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::TrustedProxies, :aggregate_failures do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('RAILS_TRUSTED_PROXIES').and_return(env_value)
  end

  describe '.fetch' do
    context 'without env setting' do
      let(:env_value) { nil }

      it 'falls back to localhost' do
        expect(described_class.fetch).to eq(['127.0.0.1', '::1'])
      end
    end

    context 'with legacy env setting in Ruby syntax' do
      let(:env_value) { "['1.2.3.4']" }

      it 'parses correctly' do
        expect(described_class.fetch).to eq(['1.2.3.4'])
      end
    end

    context 'with valid IP addresses and hostnames' do
      let(:env_value) { '1.2.3.4/24,::2,google.com' }

      it 'parses correctly' do
        expect(described_class.fetch).to include('1.2.3.4/24', '::2', a_kind_of(String)) # There may be one more element, depending on IPv6 availability.
      end
    end

    context 'with invalid IP addresses and hostnames' do
      let(:env_value) { '1.2.3.4.5,:::::2,nonexisting' }

      before do
        allow(described_class).to receive(:warn)
      end

      it 'filters everything out' do
        expect(described_class.fetch).to be_empty
        expect(described_class).to have_received(:warn).exactly(3)
      end
    end
  end
end
