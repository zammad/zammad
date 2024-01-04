# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SMIMEMetaInformationData < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    SMIMECertificate.in_batches.each_record do |record|
      begin
        cert = Certificate::X509::SMIME.new(record.pem)
        data = {
          email_addresses: cert.email_addresses,
          issuer_hash:     cert.issuer.hash.to_s(16),
          subject_hash:    cert.subject.hash.to_s(16)
        }
      rescue
        Rails.logger.warn <<~TEXT.squish
          SMIME: The migration of the certificate with fingerprint #{record.fingerprint} failed.
          The certificate might not be usable anymore.
        TEXT

        data = {
          email_addresses: [],
          issuer_hash:     '',
          subject_hash:    ''
        }
      end

      record.update!(data)
    end
  end
end
