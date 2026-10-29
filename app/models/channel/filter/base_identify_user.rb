# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::Filter::BaseIdentifyUser
  # The system account stands in for a mail without any sender address.
  def self.user_from_sender(mail)
    email = mail[:'x-zammad-customer-email'].presence || mail[:from_email]
    return User.find(1) if email.blank?

    user_create(
      login:     mail[:'x-zammad-customer-login'] || email,
      firstname: mail[:'x-zammad-customer-firstname'] || mail[:from_display_name],
      lastname:  mail[:'x-zammad-customer-lastname'],
      email:     email,
    )
  end

  def self.user_create(attrs, role_ids = nil)
    find_or_create_user(attrs, role_ids:, without_email: false)
  end

  # For the sender of a mail that could not be processed, whose address may be broken.
  def self.user_create_without_email(attrs)
    find_or_create_user(attrs, role_ids: nil, without_email: true)
  end

  def self.find_or_create_user(attrs, role_ids:, without_email:)
    populate_attributes!(attrs, role_ids: role_ids)

    if attrs[:login]
      attrs[:login] = EmailHelper::Idn.to_unicode(attrs[:login]).strip
    end

    # An address that is still invalid after sanitizing is kept as the login only,
    # so that no reply goes out to it and later mails from it find the same user.
    attrs.delete(:email) if without_email || !EmailAddressValidation.new(attrs[:email]).valid?

    if (user = existing_user(attrs))
      if user.no_name? && attrs[:firstname].present?
        user.name_from_channel_import = true
        user.update!(attrs.slice(:firstname))
      end
    elsif (user = User.create!(attrs.merge(name_from_channel_import: true)))
      user.update!(updated_by_id: user.id, created_by_id: user.id)
    end

    user
  end

  def self.existing_user(attrs)
    return User.by_login_or_email(attrs[:login]).take if attrs[:email].blank?

    User.by_login_or_email(attrs[:email]).take
  end

  def self.populate_attributes!(attrs, **extras)
    email = sanitize_email(attrs[:email])

    # A repaired address is marked as possibly wrong; one that stays invalid is dropped anyway.
    if (attrs[:email].match?(%r{\S\s+\S}) || attrs[:email].match?(%r{^<|>$})) && EmailAddressValidation.new(email).valid?
      attrs[:preferences] = { mail_delivery_failed:        true,
                              mail_delivery_failed_reason: 'invalid email',
                              mail_delivery_failed_data:   Time.zone.now }
    end

    attrs.merge!(
      email:         email,
      firstname:     sanitize_name(attrs[:firstname]),
      lastname:      sanitize_name(attrs[:lastname]),
      password:      '',
      active:        true,
      role_ids:      extras[:role_ids] || Role.signup_role_ids,
      updated_by_id: 1,
      created_by_id: 1
    )
  end

  def self.sanitize_name(string)
    return '' if string.nil?

    string.strip
          .delete('"')
          .delete_prefix("'")
          .delete_suffix("'")
          .gsub(%r{.+?\s\(.+?\)$}, '')
  end

  def self.sanitize_email(string)
    string += '@local' if string.exclude?('@')

    string = string.downcase
          .strip
          .delete('"')
          .delete("'")
          .delete(' ') # see https://github.com/zammad/zammad/issues/2254
          .sub(%r{^<|>$}, '')        # see https://github.com/zammad/zammad/issues/2254
          .sub(%r{\A'(.*)'\z}, '\1') # see https://github.com/zammad/zammad/issues/2154
          .gsub(%r{\s}, '')          # see https://github.com/zammad/zammad/issues/2198
          .delete_suffix('.')

    EmailHelper::Idn.to_unicode(string)
  end
end
