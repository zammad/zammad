# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Validation for email addresses

class EmailAddressValidation

  attr_reader :email_address

  # @param [String] email_address Email address to be validated
  def initialize(email_address)
    @email_address = email_address
  end

  def to_s
    email_address
  end

  # Checks if the email address has a valid format.
  # Reports email addresses without dot in domain as valid (zammad@localhost).
  #
  # @param mx [Boolean] check only syntax or MX as well
  #
  # @return [true]  if email address has valid format
  # @return [false] if email address has no valid format
  def valid?(check_mx: false)
    valid!(check_mx:)
  rescue InvalidEmailAddressError
    false
  end

  def valid!(check_mx: false)
    error_message = EmailAddressValidator.error email_address, host_validation: check_mx ? :mx : :syntax
    return true if error_message.blank?

    raise InvalidEmailAddressError, error_message
  end

  class InvalidEmailAddressError < StandardError
    def initialize(message = '')
      super("The email address is invalid: #{message}")
    end
  end

end
