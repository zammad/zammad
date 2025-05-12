# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Account::PhoneNumbers, :aggregate_failures do
  let(:options)  { { access_token: '1234', business_id: '1234' } }
  let(:instance) { described_class.new(**options) }

  describe '.all' do
    before do
      allow_any_instance_of(WhatsappSdk::Api::PhoneNumbers).to receive(:list).and_return(internal_response)
    end

    let(:internal_response) do
      Struct.new(:records).new(internal_response_data)
    end
    let(:internal_response_data) do
      [
        Struct.new(:id, :display_phone_number, :verified_name).new('888', '+49 888 888', 'Test Corp 8'),
        Struct.new(:id, :display_phone_number, :verified_name).new('999', '+49 999 999', 'Test Corp 9'),
      ]
    end

    it 'returns numbers' do
      expect(instance.all).to eq({ '888' => 'Test Corp 8 (+49 888 888)', '999' => 'Test Corp 9 (+49 999 999)' })
    end

    context 'with empty response' do
      let(:internal_response) { Struct.new(:records).new(nil) }

      it 'returns empty array' do
        expect(instance.all).to eq([])
      end
    end

    context 'without business_id' do
      let(:options)  { { access_token: '1234' } }

      it 'fails with an error' do
        expect { instance.all }.to raise_error(ArgumentError, "The required parameter 'business_id' is missing.")
      end
    end

    context 'with unsuccessful response' do
      before do
        exception = WhatsappSdk::Api::Responses::HttpResponseError.new(
          body:        Struct.new(:error).new({ 'message' => 'error message' }),
          http_status: 500,
        )
        allow_any_instance_of(WhatsappSdk::Api::PhoneNumbers).to receive(:list).and_raise(exception)
      end

      it 'raises an error' do
        expect { instance.all }.to raise_error(Whatsapp::Client::CloudAPIError)
      end
    end
  end

  describe '.get' do
    before do
      allow_any_instance_of(WhatsappSdk::Api::PhoneNumbers).to receive(:get).with(1234).and_return(internal_response)
    end

    let(:internal_response) do
      Struct.new(:display_phone_number, :verified_name).new('+49 888 888', 'Test Corp 8')
    end

    it 'returns numbers' do
      expect(instance.get(1234)).to eq({ phone_number: '+49 888 888', name: 'Test Corp 8' })
    end

    context 'with empty response' do
      let(:internal_response) { nil }

      it 'returns nil' do
        expect(instance.get(1234)).to be_nil
      end
    end

    context 'with unsuccessful response' do
      before do
        exception = WhatsappSdk::Api::Responses::HttpResponseError.new(
          body:        Struct.new(:error).new({ 'message' => 'error message' }),
          http_status: 500,
        )
        allow_any_instance_of(WhatsappSdk::Api::PhoneNumbers).to receive(:get).with(1234).and_raise(exception)
      end

      it 'raises an error' do
        expect { instance.get(1234) }.to raise_error(Whatsapp::Client::CloudAPIError)
      end
    end
  end
end
