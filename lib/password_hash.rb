# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module PasswordHash
  include ApplicationLib

  extend self

  def crypt(password)
    # take a fresh Argon2::Password instances to ensure randomized salt
    Argon2::Password.new(secret: secret).create(password)
  end

  def verified?(pw_hash, password)
    Argon2::Password.verify_password(password, pw_hash, secret)
  rescue
    false
  end

  def crypted?(pw_hash)
    return false if !pw_hash
    return true if hashed_argon2?(pw_hash)
    return true if hashed_sha2?(pw_hash)

    false
  end

  def legacy?(pw_hash, password)
    return false if pw_hash.blank?
    return false if !password

    return true if sha2?(pw_hash, password)
    return true if hashed_argon2i?(pw_hash, password)

    false
  end

  def hashed_sha2?(pw_hash)
    pw_hash.start_with?('{sha2}')
  end

  def hashed_argon2?(pw_hash)
    Argon2::Password.valid_hash?(pw_hash)
  end

  def hashed_argon2i?(pw_hash, password)
    # taken from: https://github.com/technion/ruby-argon2/blob/7e1f4a2634316e370ab84150e4f5fd91d9263713/lib/argon2.rb#L33
    return false if !pw_hash.match?(%r{^\$argon2i\$.{,112}})

    # Argon2::Password.verify_password verifies argon2i hashes, too
    verified?(pw_hash, password)
  end

  def sha2(password)
    crypted = Digest::SHA2.hexdigest(password)
    "{sha2}#{crypted}"
  end

  private

  def sha2?(pw_hash, password)
    return false if !hashed_sha2?(pw_hash)

    pw_hash == sha2(password)
  end

  def secret
    @secret ||= Setting.get('application_secret')
  end
end
