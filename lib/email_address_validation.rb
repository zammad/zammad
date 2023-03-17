# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
    host_validation_type = check_mx ? :mx : :syntax

    EmailAddressValidator.valid? email_address, host_validation: host_validation_type
  end
end
