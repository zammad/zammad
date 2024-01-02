# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::PrivateKey
  attr_reader :uid, :pem, :secret

  def self.read(pem, secret)
    begin
      new(pem, secret)
    rescue OpenSSL::PKey::PKeyError
      raise Exceptions::UnprocessableEntity, __('The private key is not valid for S/MIME usage. Please check the key format and the secret.')
    end
  end

  def initialize(pem, secret)
    @key = OpenSSL::PKey.read(pem, secret)

    @uid    = determine_uid
    @pem    = @key.to_pem
    @secret = secret
  end

  def valid_smime_private_key?
    return false if !rsa? && !ec?

    true
  end

  def valid_smime_private_key!
    return if valid_smime_private_key?

    message = __('The private key is not valid for S/MIME usage. Please check the key cryptographic algorithm.')

    Rails.logger.error { "SMIME::PrivateKey: #{message}" }
    Rails.logger.error { "SMIME::PrivateKey:\n #{@key.to_pem}" }

    raise Exceptions::UnprocessableEntity, message
  end

  def rsa?
    @key.class.name.end_with?('RSA')
  end

  def ec?
    @key.class.name.end_with?('EC')
  end

  private

  def determine_uid
    return @key.public_key.n.to_s(16) if rsa?

    OpenSSL::Digest.new('SHA1', @key.public_to_der).to_s
  end
end
