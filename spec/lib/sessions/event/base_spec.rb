# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event::Base do

  describe '#remote_ip' do
    let(:instance) { described_class.new(headers:, clients: {}) }

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

      let(:trusted_proxies) { ['127.0.0.1', '::1'] }

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

    end

  end
end
