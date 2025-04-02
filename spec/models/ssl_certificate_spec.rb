# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SSLCertificate, :aggregate_failures, type: :model do

  let(:fixture)     { 'RootCA' }
  let(:certificate) { create(:ssl_certificate, fixture: fixture) }

  describe '.create' do
    context 'when certificate is RootCA' do

      it 'imports correctly' do
        expect(certificate)
          .to have_attributes(
            fingerprint: 'de4abd259187d7b5f2713ff7a97eb54dd5fe9d86',
            subject:     '/emailAddress=RootCA@example.com/C=DE/ST=Berlin/L=Berlin/O=Example Security/OU=IT Department/CN=example.com',
            not_before:  Time.zone.parse('2023-08-01 09:47:39 UTC'),
            not_after:   Time.zone.parse('2043-07-27 09:47:39 UTC'),
          )
      end
    end

    context 'when certificate is IntermediateCA' do
      let(:fixture) { 'IntermediateCA' }

      it 'imports correctly' do
        expect(certificate)
          .to have_attributes(
            fingerprint: 'd1badcd237d6d2c6f0c62b5ccb21c2130b24855e',
            subject:     '/C=DE/ST=Berlin/O=Example Security/OU=IT Department/CN=example.com/emailAddress=IntermediateCA@example.com',
            not_before:  Time.zone.parse('2023-08-01 09:47:39 UTC'),
            not_after:   Time.zone.parse('2043-07-27 09:47:39 UTC'),
          )
      end
    end

    context 'when certificate is connection certificate' do
      let(:certificate_content) { File.read(Localhost::Authority.fetch('localhost').certificate_path) }
      let(:certificate)         { create(:ssl_certificate, certificate: certificate_content) }

      it 'imports correctly' do
        expect(certificate)
          .to have_attributes(
            subject: 'DNS:localhost'
          )
      end
    end
  end

  describe '#certificate_parsed' do
    context 'when certificate is valid' do
      it 'returns certificate' do
        expect(certificate.certificate_parsed).to be_an_instance_of(Certificate::X509::SSL)
      end
    end

    context 'when certificate is not valid' do
      it 'raises an error' do
        certificate.update_columns certificate: 'blablabla'
        certificate.instance_variable_set('@certificate_parsed', nil) # rubocop:disable Performance/StringIdentifierArgument

        expect { certificate.reload.certificate_parsed }.to raise_error 'This is not a valid X509 certificate. Please check the certificate format.'
      end
    end
  end

  describe 'validations' do
    describe 'certificate validation' do
      context 'when certificate is not valid' do
        let(:fixture)     { 'smime1@example.com' }
        let(:certificate) { build(:ssl_certificate, fixture: fixture) }

        it 'adds a base error' do
          certificate.save

          expect(certificate.errors[:base]).to be_present
        end
      end
    end
  end
end
