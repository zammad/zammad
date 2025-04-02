# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
  end

  describe '.extract_metadata' do

    it 'imports CA certificates correctly' do
      expect(create(:ssl_certificate, fixture: 'RootCA')).to have_attributes(
        fingerprint: 'de4abd259187d7b5f2713ff7a97eb54dd5fe9d86',
        subject:     '/emailAddress=RootCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com',
        not_before:  Time.zone.parse('2023-08-01 09:47:39 UTC'),
        not_after:   Time.zone.parse('2043-07-27 09:47:39 UTC'),
      )
      expect(create(:ssl_certificate, fixture: 'IntermediateCA')).to have_attributes(
        fingerprint: 'd1badcd237d6d2c6f0c62b5ccb21c2130b24855e',
        subject:     '/C=DE/ST=Berlin/O=Example Security/OU=IT Department/CN=example.com/emailAddress=IntermediateCA@example.com',
        not_before:  Time.zone.parse('2023-08-01 09:47:39 UTC'),
        not_after:   Time.zone.parse('2043-07-27 09:47:39 UTC'),
      )
    end

    it 'imports connection certificates correctly' do
      certificate = File.read(Localhost::Authority.fetch('localhost').certificate_path)
      expect(create(:ssl_certificate, certificate: certificate)).to have_attributes(
        subject: 'DNS:localhost',
      )
    end

    it 'rejects other certificates' do
      expect { create(:ssl_certificate, certificate: Rails.root.join('spec/fixtures/files/smime/smime1@example.com.crt').read) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The certificate is not valid for SSL usage. Please check e.g. the validity period or the extensions.')
    end
  end
end
