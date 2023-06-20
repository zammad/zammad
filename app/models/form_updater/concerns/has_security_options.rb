# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module FormUpdater::Concerns::HasSecurityOptions # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  # TODO: we do want to split this up into multiple concerns during the PGP implementation (or maybe a service?).

  def resolve
    if smime_active? && email_channel? && agent?
      result_initialize_field('security')

      result['security'][:allowed] = smime_allowed_values
      result['security'][:value] = smime_default_value
      result['security'][:securityMessages] = @messages if @messages.present?
    end

    super
  end

  private

  def smime_active?
    Setting.get('smime_integration')
  end

  def email_channel?
    data['articleSenderType'] == 'email-out' || data.dig('article', 'articleType') == 'email'
  end

  def agent?
    current_user.permissions?(['ticket.agent'])
  end

  def smime_config
    Setting.get('smime_config')
  end

  def smime_allowed_values
    result = []

    # default messages
    # TODO: Make no sense to add these messages to the result for empty group and sender?
    add_encryption_message(__('No recipient found.'))
    add_sign_message(__('Certificate not found.'))

    result.push('encryption') if smime_encryption?
    result.push('sign') if smime_sign?

    result
  end

  def smime_default_value
    result = smime_allowed_values # fallback

    return result if !smime_config['group_id'] || !data['group_id']

    filter_smime_config_default_values(result)
  end

  def filter_smime_config_default_values(result)
    { 'default_sign' => 'sign', 'default_encryption' => 'encryption' }.each do |type, selector|
      next if !smime_config['group_id'][type]
      next if smime_config['group_id'][type][data['group_id'].to_s]

      result.delete(selector)
    end

    result
  end

  def smime_encryption?
    return false if !data['customer_id'] && !data['cc'] && !data.dig('article', 'to') && !data.dig('article', 'cc')

    recipients = verified_recipient_addresses
    return false if recipients.blank?

    recipients_have_valid_certificate?(recipients)
  end

  def recipient_addresses
    customer_recipient + target_recipients + additional_recipients
  end

  def customer_recipient
    return [] if data['customer_id'].nil?

    customer = ::User.find_by(id: data['customer_id'])

    return [] if !customer || customer.email.empty?

    [customer.email]
  end

  def target_recipients
    return [] if data.dig('article', 'to').nil?

    data['article']['to']
  end

  def additional_recipients
    result = []

    result.concat data['cc'] if data['cc'].present?
    result.concat data['article']['cc'] if data.dig('article', 'cc').present?

    result
  end

  def verified_recipient_addresses
    list = Mail::AddressList.new(recipient_addresses.compact.join(',').to_s)
    list.addresses.map(&:address)
  end

  def recipients_have_valid_certificate?(recipients)
    result = false

    begin
      certs = SMIMECertificate.for_recipipent_email_addresses!(recipients)

      result = get_encryption_result(certs, recipients)
    rescue => e
      result = false
      add_encryption_message(e.message)
    end

    result
  end

  def get_encryption_result(certs, recipients)
    result = false

    if certs
      result = certs.none?(&:expired?)

      if certs.any?(&:expired?)
        add_encryption_message(__('Certificates found for %s, but expired.'), [recipients.join(', ')])
      else
        add_encryption_message(__('Certificates found for %s.'), [recipients.join(', ')])
      end
    end

    result
  end

  def smime_sign?
    return false if !data['group_id']

    group = Group.find_by(id: data['group_id'])
    return false if !group

    group_has_valid_certificate?(group)
  end

  def group_has_valid_certificate?(group)
    result = false

    begin
      list = Mail::AddressList.new(group.email_address.email)
      from = list.addresses.first.to_s
      cert = SMIMECertificate.for_sender_email_address(from)

      result = get_sign_result(cert, group.email_address.email)
    rescue NoMethodError
      result = false
      add_sign_message(__('Invalid email address.'))
    rescue => e
      result = false
      add_sign_message(e.message)
    end

    result
  end

  def get_sign_result(cert, email)
    result = false

    if cert
      result = !cert.expired?

      if cert.expired?
        add_sign_message(__('Certificate for %s found, but expired.'), [email])
      else
        add_sign_message(__('Certificate for %s found.'), [email])
      end
    else
      add_sign_message(__('No certificate for %s found.'), [email])
    end

    result
  end

  def add_encryption_message(message, placeholders = [])
    add_message('encryption', message, placeholders)
  end

  def add_sign_message(message, placeholders = [])
    add_message('sign', message, placeholders)
  end

  def add_message(option, message, placeholders)
    @messages ||= {}
    @messages[option] = {
      message:            message,
      messagePlaceholder: placeholders,
    }
  end
end
