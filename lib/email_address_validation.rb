# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
  # @return [true]  if email address has valid format
  # @return [false] if email address has no valid format
  def valid_format?
    # NOTE: Don't use ValidEmail2::Address.valid? here because it requires the
    # email address to have a dot in its domain.
    @valid_format ||= email_address.match?(URI::MailTo::EMAIL_REGEXP)
  end

  # Checks if the domain of the email address has a valid MX record.
  #
  # @return [true]  if email address domain has an MX record
  # @return [false] if email address domain has no MX record
  def valid_mx?
    return @valid_mx if @valid_mx

    validated_email_address = ValidEmail2::Address.new(email_address)
    @valid_mx               = validated_email_address&.valid_mx?
  end

end
