# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Incoming::Message do
  let(:instance) { described_class.new(**params) }

  let(:params) do
    {
      access_token:    Faker::Omniauth.unique.facebook[:credentials][:token],
      phone_number_id: Faker::Number.unique.number(digits: 15),
    }
  end

  describe '.mark_as_read' do
    let(:message_id) { "wamid.#{Faker::Crypto.unique.sha1}==" }

    before do
      allow_any_instance_of(WhatsappSdk::Api::Messages).to receive(:read_message).and_return(internal_response)
    end

    context 'with successful response' do
      let(:internal_response) do
        Struct.new(:data, :error).new(Struct.new(:success).new(true), nil)
      end

      it 'returns true' do
        expect(instance.mark_as_read(message_id:)).to be(true)
      end
    end

    context 'with unsuccessful response' do
      let(:internal_response) { Struct.new(:data, :error, :raw_response).new(nil, Struct.new(:message).new('error message'), '{}') }

      it 'raises an error' do
        expect { instance.mark_as_read(message_id:) }.to raise_error(Whatsapp::Client::CloudAPIError, 'error message')
      end
    end
  end
end
