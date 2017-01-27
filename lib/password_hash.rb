# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module PasswordHash
  include ApplicationLib

  # rubocop:disable Style/ModuleFunction
  extend self

  def crypt(password)
    argon2.create(password)
  end

  def verified?(pw_hash, password)
    Argon2::Password.verify_password(password, pw_hash, secret)
  rescue
    false
  end

  def crypted?(pw_hash)
    return if !pw_hash
    # taken from: https://github.com/technion/ruby-argon2/blob/7e1f4a2634316e370ab84150e4f5fd91d9263713/lib/argon2.rb#L33
    return if pw_hash !~ /^\$argon2i\$.{,112}/
    true
  end

  def legacy?(pw_hash, password)
    return if pw_hash.blank?
    return if !password
    legacy_sha2?(pw_hash, password)
  end

  private

  def legacy_sha2?(pw_hash, password)
    return if !pw_hash.start_with?('{sha2}')
    crypted = Digest::SHA2.hexdigest(password)
    pw_hash == "{sha2}#{crypted}"
  end

  def argon2
    return @argon2 if @argon2
    @argon2 = Argon2::Password.new(secret: secret)
  end

  def secret
    Setting.get('application_secret')
  end
end
