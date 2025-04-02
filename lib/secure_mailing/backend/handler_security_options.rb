# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::Backend::HandlerSecurityOptions < SecureMailing::Backend::Handler

  SECURITY_OPTIONS_METHOD_STATUS = Struct.new(
    :possible?,
    :active_by_default?,
    :message,
    :message_placeholders,
    keyword_init: true
  )

  SECURITY_OPTIONS_RESULT = Struct.new(
    :type,
    :encryption,
    :signing,
    keyword_init: true
  )

  attr_reader :ticket, :article

  def initialize(ticket:, article:)
    super()
    @ticket = ticket
    @article = article
  end

  def process
    SECURITY_OPTIONS_RESULT.new(
      type:       type,
      signing:    check_signing,
      encryption: check_encryption,
    )
  end

  private

  def sign_security_options_status_default_message
    raise NotImplementedError
  end

  def encryption_security_options_status_default_message
    __('There was no recipient found.')
  end

  def check_signing
    result = SECURITY_OPTIONS_METHOD_STATUS.new(
      message:              sign_security_options_status_default_message,
      message_placeholders: [],
    )
    result[:possible?] = can_sign?(result)
    result[:active_by_default?] = signing_default?(result)
    result
  end

  def check_encryption
    result = SECURITY_OPTIONS_METHOD_STATUS.new(
      message:              encryption_security_options_status_default_message,
      message_placeholders: [],
    )
    result[:possible?] = can_encrypt?(result)
    result[:active_by_default?] = encryption_default?(result)
    result
  end

  def config
    raise NotImplementedError
  end

  def group_has_valid_secure_objects?
    raise NotImplementedError
  end

  def recipients_have_valid_secure_objects?
    raise NotImplementedError
  end

  def signing_default?(signing_result)
    return false if !signing_result.possible?
    return true if !config.dig('group_id', 'default_sign') || !ticket['group_id']

    config['group_id']['default_sign'][ticket['group_id'].to_s]
  end

  def can_sign?(signing_result)
    return false if !ticket['group_id']

    group = Group.find_by(id: ticket['group_id'])
    return false if !group

    group_email = group.email_address&.email
    return false if group_email.blank?

    group_has_valid_secure_objects?(signing_result, group_email)
  end

  def encryption_default?(encryption_result)

    return false if !encryption_result.possible?
    return true if !config.dig('group_id', 'default_encryption') || !ticket['group_id']

    config['group_id']['default_encryption'][ticket['group_id'].to_s]
  end

  def can_encrypt?(encryption_result)
    return false if !ticket['customer_id'] && !ticket['cc'] && !article['to'] && !article['cc']

    recipients = verified_recipient_addresses
    return false if recipients.blank?

    recipients_have_valid_secure_objects?(encryption_result, recipients)
  end

  def verified_recipient_addresses
    list = Mail::AddressList.new(recipient_addresses.compact.join(','))
    list.addresses.map(&:address).uniq
  end

  def recipient_addresses
    customer_recipient + target_recipients + additional_recipients
  end

  def customer_recipient
    return [] if ticket['customer_id'].nil?

    customer = ::User.find_by(id: ticket['customer_id'])

    return [] if !customer || customer.email.empty?

    [customer.email]
  end

  def target_recipients
    [article['to']].compact
  end

  def additional_recipients
    [ticket['cc'].presence, article['cc'].presence].compact
  end

  def from(group_email)
    list = Mail::AddressList.new(group_email)
    list.addresses.first.to_s
  end
end
