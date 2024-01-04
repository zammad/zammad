# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Certificate::X509 < OpenSSL::X509::Certificate
  attr_reader :fingerprint

  def initialize(cert)
    super(cert.gsub(%r{(?:TRUSTED\s)?(CERTIFICATE---)}, '\1'))

    @fingerprint = OpenSSL::Digest.new('SHA1', to_der).to_s
  end

  def extensions_as_hash
    extensions.each_with_object({}) do |ext, hash|
      hash[ext.oid] = ext.value.split(',').map(&:strip)
    end
  end

  def ca?
    extensions_as_hash.fetch('basicConstraints', '').include?('CA:TRUE')
  end

  def effective?
    Time.zone.now >= not_before
  end

  def expired?
    Time.zone.now > not_after
  end

  def usable?
    effective? && !expired?
  end

  def signature?
    extensions_as_hash.fetch('keyUsage', ['Digital Signature']).include?('Digital Signature')
  end

  def encryption?
    extensions_as_hash.fetch('keyUsage', ['Key Encipherment']).include?('Key Encipherment')
  end

  def key_match?(pem, secret)
    key = OpenSSL::PKey.read(pem, secret)
    key.compare?(public_key)
  end
end
