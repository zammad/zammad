# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::PGP::SecurityOptions < SecureMailing::Backend::HandlerSecurityOptions

  def type
    'PGP'
  end

  private

  def sign_security_options_status_default_message
    __('There was no PGP key found.')
  end

  def config
    Setting.get('pgp_config')
  end

  def group_has_valid_secure_objects?(signing_result, group_email)
    begin
      sign_key = PGPKey.find_by_uid(from(group_email), only_valid: false, secret: true)

      return key_valid?(signing_result, sign_key, group_email)
    rescue ActiveRecord::RecordNotFound
      signing_result.message = __('The PGP key for %s was not found.')
      signing_result.message_placeholders = [group_email]
    rescue => e
      signing_result.message = e.message
    end

    false
  end

  def key_valid?(signing_result, sign_key, email)
    result = false

    if sign_key
      result = !sign_key.expired?

      signing_result.message = if sign_key.expired?
                                 __('The PGP key for %s was found, but has expired.')
                               else
                                 __('The PGP key for %s was found.')
                               end
    else
      signing_result.message = __('The PGP key for %s was not found.')
    end

    signing_result.message_placeholders = [email]

    result
  end

  def recipients_have_valid_secure_objects?(encryption_result, recipients)
    keys = recipients.map do |recipient|
      PGPKey.find_by_uid(recipient, only_valid: false)
    rescue ActiveRecord::RecordNotFound
      encryption_result.message = __('The PGP key for %s was not found.')
      encryption_result.message_placeholders = [recipient]
      return false
    end

    keys_valid?(encryption_result, keys, recipients)
  rescue => e
    encryption_result.message = e.message
    false
  end

  def keys_valid?(encryption_result, keys, recipients)
    result = false

    if keys
      result = keys.none?(&:expired?)

      encryption_result.message = if keys.any?(&:expired?)
                                    __('There were PGP keys found for %s, but at least one of them has expired.')
                                  else
                                    __('The PGP keys for %s were found.')
                                  end
      encryption_result.message_placeholders = [recipients.join(', ')]
    else
      encryption_result.message = __('The PGP keys for %s were not found.')
    end

    result
  end
end
