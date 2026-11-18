# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'viewpoint' # Only load this gem when it is really used.

RSpec.describe Sequencer::Unit::Exchange::Connection, sequencer: :unit do
  let(:endpoint)       { 'https://exchange.example.com/EWS/Exchange.asmx' }
  let(:ews_connection) { process(ews_config: ews_config)[:ews_connection] }

  before do
    allow(Viewpoint::EWSClient).to receive(:new).and_call_original
  end

  context 'with basic authentication' do
    let(:ews_config) { { endpoint: endpoint, auth_type: 'basic', user: 'user@example.com', password: 'secret' } }

    it 'creates the client with the user and password' do
      ews_connection

      expect(Viewpoint::EWSClient).to have_received(:new)
        .with({ endpoint: endpoint, type: 'basic', token: nil, user: 'user@example.com', password: 'secret' }, anything)
    end

    it 'verifies SSL against the store with the custom SSL certificates' do
      certificate = create(:ssl_certificate, fixture: 'RootCA')

      ews_connection

      expect(Viewpoint::EWSClient).to have_received(:new)
        .with(anything, { http_opts: { cert_store: satisfy { |store| store.verify(certificate.certificate_parsed) } } })
    end

    context 'with a blank password' do
      let(:ews_config) { super().merge(password: '') }

      it 'creates the client without a password' do
        ews_connection

        expect(Viewpoint::EWSClient).to have_received(:new).with(include(password: nil), anything)
      end
    end

    context 'with disabled SSL verification' do
      let(:ews_config) { super().merge(disable_ssl_verify: true) }

      it 'creates the client without SSL verification' do
        ews_connection

        expect(Viewpoint::EWSClient).to have_received(:new)
          .with(anything, { http_opts: { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE } })
      end
    end
  end

  context 'with OAuth authentication' do
    let(:ews_config) { { endpoint: endpoint, auth_type: 'oauth', access_token: 'token' } }

    it 'authenticates with the access token' do
      request = stub_request(:post, endpoint).with(headers: { 'Authorization' => 'Bearer token' })

      ews_connection.ews.connection.post('<soap/>')

      expect(request).to have_been_requested
    end
  end

  context 'without a given configuration' do
    let(:ews_config) { nil }

    before do
      Setting.set('exchange_config', { endpoint: endpoint, auth_type: 'oauth' })
      Setting.set('exchange_oauth', { access_token: 'stored-token' })
    end

    it 'authenticates with the stored access token' do
      request = stub_request(:post, endpoint).with(headers: { 'Authorization' => 'Bearer stored-token' })

      ews_connection.ews.connection.post('<soap/>')

      expect(request).to have_been_requested
    end
  end
end
