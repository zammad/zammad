# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::Base do

  describe '#initialize' do
    it 'does not accept unknown params' do
      expect { described_class.new(clients: {}, user_id: 1) }.to raise_error(ArgumentError)
    end
  end

  describe '#remote_ip' do
    let(:instance) { described_class.new(headers:) }

    context 'without X-Forwarded-For' do
      let(:headers) { {} }

      it 'returns no value' do
        expect(instance.remote_ip).to be_nil
      end
    end

    context 'with X-Forwarded-For' do
      before do
        allow(Rails.application.config.action_dispatch).to receive(:trusted_proxies).and_return(trusted_proxies)
      end

      let(:trusted_proxies) { [IPAddr.new('127.0.0.1'), IPAddr.new('::1')] }

      context 'with external IP' do

        let(:headers) { { 'X-Forwarded-For' => '1.2.3.4 , 5.6.7.8, 127.0.0.1 , ::1' } }

        it 'returns the correct value' do
          expect(instance.remote_ip).to eq('5.6.7.8')
        end
      end

      context 'without external IP' do

        let(:headers) { { 'X-Forwarded-For' => ' 127.0.0.1 , ::1' } }

        it 'returns no value' do
          expect(instance.remote_ip).to be_nil
        end
      end

      context 'with proxies in a trusted address range' do
        let(:trusted_proxies) { [IPAddr.new('192.168.66.0/24')] }
        let(:headers)         { { 'X-Forwarded-For' => '1.2.3.4, 192.168.66.1, 192.168.66.2' } }

        it 'returns the address before the range' do
          expect(instance.remote_ip).to eq('1.2.3.4')
        end
      end

      context 'with a value that is not an IP address' do
        let(:headers) { { 'X-Forwarded-For' => 'unknown, 127.0.0.1' } }

        it 'returns the value' do
          expect(instance.remote_ip).to eq('unknown')
        end
      end

    end

  end
end
