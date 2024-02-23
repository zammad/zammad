# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Outgoing::Message::Text do
  let(:instance) { described_class.new(**params) }

  let(:params) do
    {
      access_token:     Faker::Omniauth.unique.facebook[:credentials][:token],
      phone_number_id:  Faker::Number.unique.number(digits: 15),
      recipient_number: Faker::PhoneNumber.unique.cell_phone_in_e164,
    }
  end

  describe '.deliver' do
    let(:body) { 'foobar' }

    before do
      allow_any_instance_of(WhatsappSdk::Api::Messages).to receive(:send_text).and_return(internal_response)
    end

    context 'with successful response' do
      let(:message_id) { "wamid.#{Faker::Crypto.unique.sha1}==" }
      let(:response)   { { id: message_id } }

      let(:internal_response) do
        Struct.new(:data, :error).new(Struct.new(:messages).new([Struct.new(:id).new(message_id)]), nil)
      end

      it 'returns sent message id' do
        expect(instance.deliver(body:)).to eq(response)
      end
    end

    context 'with unsuccessful response' do
      let(:internal_response) { Struct.new(:data, :error, :raw_response).new(nil, Struct.new(:message).new('error message'), '{}') }

      it 'raises an error' do
        expect { instance.deliver(body:) }.to raise_error(Whatsapp::Client::CloudAPIError, 'error message')
      end
    end
  end
end
