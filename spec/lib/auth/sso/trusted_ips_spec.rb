# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::Sso::TrustedIps do
  subject(:trusted_ips) { described_class.new(value) }

  describe '#blank?' do
    context 'when value is empty string' do
      let(:value) { '' }

      it { is_expected.to be_blank }
    end

    context 'when value is nil' do
      let(:value) { nil }

      it { is_expected.to be_blank }
    end

    context 'when value contains entries' do
      let(:value) { '192.168.1.1' }

      it { is_expected.not_to be_blank }
    end
  end

  describe '#include?' do
    context 'when configured with an exact IP' do
      let(:value) { '192.168.1.1' }

      it 'matches the exact IP' do
        expect(trusted_ips.include?('192.168.1.1')).to be true
      end

      it 'does not match a different IP' do
        expect(trusted_ips.include?('192.168.1.2')).to be false
      end
    end

    context 'when configured with a CIDR range' do
      let(:value) { '10.0.0.0/8' }

      it 'matches an IP within the range' do
        expect(trusted_ips.include?('10.1.2.3')).to be true
      end

      it 'does not match an IP outside the range' do
        expect(trusted_ips.include?('192.168.1.1')).to be false
      end
    end

    context 'when configured with multiple entries' do
      let(:value) { '192.168.1.1, 10.0.0.0/8' }

      it 'matches the exact IP' do
        expect(trusted_ips.include?('192.168.1.1')).to be true
      end

      it 'matches an IP in the CIDR range' do
        expect(trusted_ips.include?('10.5.5.5')).to be true
      end

      it 'does not match an unrelated IP' do
        expect(trusted_ips.include?('1.2.3.4')).to be false
      end
    end

    context 'when the input IP is invalid' do
      let(:value) { '192.168.1.1' }

      it 'returns false' do
        expect(trusted_ips.include?('not-an-ip')).to be false
      end
    end
  end

  describe '#exclude?' do
    let(:value) { '192.168.1.1' }

    it 'returns true for an IP not in the list' do
      expect(trusted_ips.exclude?('1.2.3.4')).to be true
    end

    it 'returns false for an IP in the list' do
      expect(trusted_ips.exclude?('192.168.1.1')).to be false
    end
  end

  describe '#first_invalid_entry' do
    context 'when all entries are valid' do
      let(:value) { '192.168.1.1, 10.0.0.0/8' }

      it 'returns nil' do
        expect(trusted_ips.first_invalid_entry).to be_nil
      end
    end

    context 'when one entry is invalid' do
      let(:value) { '192.168.1.1, not-an-ip' }

      it 'returns the invalid entry' do
        expect(trusted_ips.first_invalid_entry).to eq('not-an-ip')
      end
    end

    context 'when all entries are invalid' do
      let(:value) { 'foobar' }

      it 'returns the first invalid entry' do
        expect(trusted_ips.first_invalid_entry).to eq('foobar')
      end
    end
  end
end
