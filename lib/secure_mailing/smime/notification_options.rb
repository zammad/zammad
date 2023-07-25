# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::NotificationOptions < SecureMailing::Backend::HandlerNotificationOptions
  def type
    'S/MIME'
  end

  def check_sign
    return if from_certificate.nil?
    return if from_certificate.expired?

    security_options[:sign] = { success: true }
  end

  def check_encrypt
    begin
      SMIMECertificate.for_recipient_email_addresses!(recipients)
      security_options[:encryption] = { success: true }
    rescue ActiveRecord::RecordNotFound
      # no-op
    end
  end

  private

  def from_certificate
    @from_certificate ||= begin
      list = Mail::AddressList.new(from.email)
      SMIMECertificate.for_sender_email_address(list.addresses.first.to_s)
    end
  end
end
