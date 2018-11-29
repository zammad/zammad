require 'spec_helper'

describe Clearbit::Webhook, 'valid!' do
  let(:clearbit_key) { 'clearbit_key' }

  context 'clearbit key set globally' do
    before do
      Clearbit.key = clearbit_key
    end

    context 'valid signature' do
      it 'returns true' do
        signature = generate_signature(clearbit_key, 'A-OK')

        result = Clearbit::Webhook.valid!(signature, 'A-OK')

        expect(result).to eq true
      end
    end

    context 'invalid signature' do
      it 'returns false' do
        signature = generate_signature(clearbit_key, 'A-OK')

        expect {
          Clearbit::Webhook.valid!(signature, 'TAMPERED_WITH_BODY_BEWARE!')
        }.to raise_error(Clearbit::Errors::InvalidWebhookSignature)
      end
    end
  end

  context 'clearbit key set locally' do
    context 'valid signature' do
      it 'returns true' do
        clearbit_key = 'clearbit_key'
        signature = generate_signature(clearbit_key, 'A-OK')

        result = Clearbit::Webhook.valid!(signature, 'A-OK', clearbit_key)

        expect(result).to eq true
      end
    end

    context 'invalid signature' do
      it 'returns false' do
        clearbit_key = 'clearbit_key'
        signature = generate_signature(clearbit_key, 'A-OK')

        expect {
          Clearbit::Webhook.valid!(signature, 'TAMPERED_WITH_BODY_BEWARE!', clearbit_key)
        }.to raise_error(Clearbit::Errors::InvalidWebhookSignature)
      end
    end
  end
end

describe Clearbit::Webhook, 'initialize' do
  let(:clearbit_key) { 'clearbit_key' }

  let(:env) do
    request_body = JSON.dump(id:'123', type: 'person', body: nil, status: 404)

    Rack::MockRequest.env_for('/webhook',
      method: 'POST',
      input:  request_body,
      'HTTP_X_REQUEST_SIGNATURE' => generate_signature(clearbit_key, request_body)
    )
  end

  context 'clearbit key set globally' do
    it 'returns a mash' do
      Clearbit.key = 'clearbit_key'

      webhook = Clearbit::Webhook.new(env)

      expect(webhook.status).to eq 404
    end
  end

  context 'clearbit key set locally' do
    it 'returns a mash' do
      webhook = Clearbit::Webhook.new(env, 'clearbit_key')

      expect(webhook.status).to eq 404
    end
  end
end
