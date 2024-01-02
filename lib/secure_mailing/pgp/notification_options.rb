# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::PGP::NotificationOptions < SecureMailing::Backend::HandlerNotificationOptions
  def type
    'PGP'
  end

  def check_sign
    begin
      if from_key && !from_key.expired?
        security_options[:sign] = { success: true }
      end
    rescue ActiveRecord::RecordNotFound
      # no-op
    end
  end

  def check_encrypt
    begin
      PGPKey.for_recipient_email_addresses!(recipients)
      security_options[:encryption] = { success: true }
    rescue ActiveRecord::RecordNotFound
      # no-op
    end
  end

  private

  def from_key
    @from_key ||= begin
      list = Mail::AddressList.new(from.email)
      PGPKey.find_by_uid(list.addresses.first.to_s, only_valid: false, secret: true)
    end
  end
end
