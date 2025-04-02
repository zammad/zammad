# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SMIMEMetaInformationData, db_strategy: :reset, type: :db_migration do
  let(:smime_certificate) { create(:smime_certificate, fixture: 'smime1@example.com') }
  let(:smime_object)      { Certificate::X509::SMIME.new(smime_certificate.pem) }

  describe 'migrate smime_certificates' do
    before do
      smime_certificate.update!(email_addresses: nil)
    end

    it 'stores correct meta information' do
      migrate
      expect(smime_certificate.reload).to have_attributes(
        email_addresses: smime_object.email_addresses,
        issuer_hash:     smime_object.issuer_hash,
        subject_hash:    smime_object.subject_hash,
      )
    end
  end

  describe 'migrate smime_certificates with invalid PEM' do
    before do
      smime_certificate.update!(pem: 'invalid')
    end

    it 'stores blank meta information and logs warning', :aggregate_failures do
      allow(Rails.logger).to receive(:warn)
      migrate
      expect(smime_certificate.reload).to have_attributes(
        email_addresses: [],
        issuer_hash:     '',
        subject_hash:    '',
      )
      message = <<~TEXT.squish
        SMIME: The migration of the certificate with fingerprint #{smime_certificate.fingerprint} failed.
        The certificate might not be usable anymore.
      TEXT
      expect(Rails.logger).to have_received(:warn).with(message)
    end
  end
end
