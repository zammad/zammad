# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class PGPKey < ApplicationModel
  default_scope { order(created_at: :desc, id: :desc) }

  before_validation :ensure_ascii_key, :prepare_key_info, on: :create
  before_create :prepare_domain_alias

  validates :fingerprint, uniqueness: { message: __('There is already a PGP key with the same fingerprint.') }

  KEY_BEGIN_REGEXP = %r{-----BEGIN PGP (PRIVATE|PUBLIC) KEY BLOCK-----}
  KEY_END_REGEXP = %r{-----END PGP (PRIVATE|PUBLIC) KEY BLOCK-----}

  def self.find_by_uid(uid, only_valid: true, secret: false)
    find_all_by_uid(uid, only_valid:, secret:).first.tap do |result|
      raise ActiveRecord::RecordNotFound, "The PGP key for #{uid} was not found." if result.nil?
    end
  end

  def self.find_all_by_uid(uid, only_valid: true, secret: false)
    uid = uid.downcase

    keys_selector = PGPKey.where('uids LIKE ?', "%#{uid}%")

    if domain_alias_configuration_active?
      keys_selector = PGPKey.where(['(uids LIKE ?) OR (? LIKE domain_alias)', "%#{uid}%", uid])
    end

    keys_selector = keys_selector.where(secret: true) if secret

    only_valid ? keys_selector.reject(&:expired?) : keys_selector.all
  end

  def self.for_recipient_email_addresses!(addresses)
    keys = []
    remaining_addresses = addresses.map(&:downcase)

    all.as_batches do |key|
      # intersection of both lists
      key_for = key.email_addresses & remaining_addresses
      next if key_for.blank?

      keys.push(key)

      # subtract found recipient(s)
      remaining_addresses -= key_for

      # end loop if no addresses are remaining
      break if remaining_addresses.blank?
    end

    return keys if remaining_addresses.blank?

    # When needed (still present remaining addresses) check also for alias keys, when feature is active.
    check_for_recipient_email_addresses_with_domain(keys, remaining_addresses)

    return keys if remaining_addresses.blank?

    raise ActiveRecord::RecordNotFound, "The PGP keys for #{remaining_addresses.join(', ')} could not be found."
  end

  def self.ascii_key?(given_key)
    given_key.match?(KEY_BEGIN_REGEXP) && given_key.match?(KEY_END_REGEXP)
  rescue ArgumentError => e
    return false if e.message == 'invalid byte sequence in UTF-8'

    raise e
  end

  def self.params_cleanup!(params)
    if params[:key].present?
      params[:key].strip!
      return params
    end

    return params if !params[:file].is_a? ActionDispatch::Http::UploadedFile

    params[:key] = params[:file].tempfile

    params
  end

  def self.convert_binary_key_to_ascii(binary, passphrase)
    SecureMailing::PGP::Tool.new.with_private_keyring do |pgp_tool|
      pgp_tool.import(binary)
      info = pgp_tool.info(binary)
      pgp_tool.export(info.fingerprint, passphrase, secret: info.secret).stdout
    end
  end

  def self.domain_alias_configuration_active?
    Setting.get('pgp_recipient_alias_configuration')
  end

  def self.check_for_recipient_email_addresses_with_domain(keys, remaining_addresses)
    return if !domain_alias_configuration_active?

    remaining_addresses.each do |address|
      key = find_by_uid(address, only_valid: false)
      next if key.nil?

      keys.push(key)
      remaining_addresses.delete(address)
    end
  end
  private_class_method :check_for_recipient_email_addresses_with_domain

  def key_id
    fingerprint[-16..]
  end

  def expired?
    return false if expires_at.nil?

    expires_at < Time.zone.now
  end

  def expired!
    raise "The PGP keys for #{uids} with fingerprint #{fingerprint} have expired at #{expires_at}" if expired?
  end

  def ensure_ascii_key
    raw_key_contents = read_attribute_before_type_cast('key').try(:read)

    return if raw_key_contents.nil?

    self.key = if self.class.ascii_key?(raw_key_contents)
                 raw_key_contents
               else
                 self.class.convert_binary_key_to_ascii(raw_key_contents, passphrase)
               end
  rescue => e
    errors.add(:key, e.message)
  end

  def prepare_key_info
    SecureMailing::PGP::Tool.new.with_private_keyring do |pgp_tool|
      apply_key_attrs(pgp_tool.info(key))

      # Validate the passphrase of a private key.
      if secret
        pgp_tool.import(key)
        pgp_tool.passphrase(fingerprint, passphrase)
      end
    end
  rescue => e
    errors.add(:key, e.message)
  end

  def email_addresses
    @email_addresses ||= email_addresses_from_uids(uids)
  end

  private

  def prepare_domain_alias
    return if !domain_alias

    self.domain_alias = "%@#{domain_alias}"
  end

  def apply_key_attrs(info)
    self.fingerprint = info.fingerprint
    self.uids        = info.uids.join(',').downcase
    self.created_at  = info.created_at
    self.expires_at  = info.expires_at
    self.secret      = info.secret
  end

  def email_addresses_from_uids(uids)
    entries = uids.split(',')

    entries.each_with_object([]) do |entry, result|
      email_address = entry.split.last.gsub(%r{[<>]}, '').downcase

      if !EmailAddressValidation.new(email_address).valid?
        Rails.logger.warn <<~TEXT.squish
          The PGP key #{fingerprint}
          has the malformed email address "#{email_address}"
          as part of its UID "#{entry}".
          This makes it useless in terms of PGP, please check.
        TEXT

        next
      end

      result.push(email_address)
    end
  end
end
