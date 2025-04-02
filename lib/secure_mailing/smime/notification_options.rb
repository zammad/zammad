# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME::NotificationOptions < SecureMailing::Backend::HandlerNotificationOptions
  def type
    'S/MIME'
  end

  def check_sign
    return if from_certificate.nil?
    return if !from_certificate.parsed.usable?

    security_options[:sign] = { success: true }
  end

  def check_encrypt
    begin
      SMIMECertificate.find_for_multiple_email_addresses!(recipients, filter: { key: 'public', ignore_usable: true, usage: :encryption }, blame: true)
      security_options[:encryption] = { success: true }
    rescue ActiveRecord::RecordNotFound
      # no-op
    end
  end

  private

  def from_certificate
    @from_certificate ||= begin
      list = Mail::AddressList.new(from.email)
      SMIMECertificate.find_by_email_address(list.addresses.first.to_s, filter: { key: 'private', usage: :signature, ignore_usable: false }).first
    end
  end
end
