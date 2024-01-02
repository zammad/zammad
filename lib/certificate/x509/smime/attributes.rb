# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Certificate::X509::SMIME::Attributes
  def fetch_email_addresses
    subject_alt_name = extensions_as_hash['subjectAltName']
    return [] if subject_alt_name.blank?

    subject_alt_name.each_with_object([]) do |entry, result|
      identifier, email_address = entry.split(':').map(&:downcase)

      next if identifier.exclude?('email') && identifier.exclude?('rfc822')
      next if !EmailAddressValidation.new(email_address).valid?

      result.push(email_address)
    end
  end

  def determine_uid
    return public_key.n.to_s(16) if rsa?

    OpenSSL::Digest.new('SHA1', public_key.to_der).to_s
  end
end
