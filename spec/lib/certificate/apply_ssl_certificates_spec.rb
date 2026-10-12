# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Certificate::ApplySSLCertificates, :aggregate_failures, type: :model do

  describe '.ensure_fresh_ssl_context' do
    def current_store
      OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE
    end

    context 'with a custom certificate present' do
      it 'changes the context' do
        create(:ssl_certificate, fixture: 'RootCA')
        expect { described_class.ensure_fresh_ssl_context }.to change { current_store }
        expect { described_class.ensure_fresh_ssl_context }.not_to change { current_store }
        create(:ssl_certificate, fixture: 'ChainCA')
        expect { described_class.ensure_fresh_ssl_context }.to change { current_store }
      end
    end

    context 'without custom certificates present' do
      it 'changes the context' do
        expect { described_class.ensure_fresh_ssl_context }.to change { current_store }
      end
    end

    context 'when the store is needed by the caller' do
      it 'returns the current store, also when the context was fresh already' do
        create(:ssl_certificate, fixture: 'RootCA')

        expect(described_class.ensure_fresh_ssl_context).to be(current_store)
        expect(described_class.ensure_fresh_ssl_context).to be(current_store)
      end
    end
  end

end
