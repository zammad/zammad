# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::EmailRecipientNormalizer

  class << self
    def normalize(input)
      return input if input.blank?

      addresses = parse_addresses(input)
      return input if addresses.blank?

      seen   = {}
      result = []

      addresses.each do |addr|
        normalized = normalize_address(addr, seen)
        result << normalized if normalized.present?
      end

      result.join(', ')
    rescue
      input
    end

    private

    def parse_addresses(input)
      Mail::AddressList.new(input).addresses
    rescue
      []
    end

    def normalize_address(addr, seen)
      raw_address = addr.address.to_s.strip
      return if raw_address.blank?

      is_email   = valid_email?(raw_address)
      identifier = is_email ? raw_address.downcase : raw_address
      return if seen[identifier]

      seen[identifier] = true

      return raw_address unless is_email

      email = raw_address.downcase

      user = User.find_by(email: email)
      return user.fullname(recipient_line: true) if user.present?

      display_name = addr.display_name.to_s.strip
      return Channel::EmailBuild.recipient_line(display_name, email) if display_name.present?

      email
    rescue
      fallback_address = addr.address.to_s.strip
      return if fallback_address.blank?

      is_email   = valid_email?(fallback_address)
      identifier = is_email ? fallback_address.downcase : fallback_address
      return if seen[identifier]

      seen[identifier] = true
      fallback_address
    end

    def valid_email?(value)
      EmailAddressValidation.new(value).valid?
    rescue
      false
    end
  end
end