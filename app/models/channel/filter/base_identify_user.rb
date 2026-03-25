# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::Filter::BaseIdentifyUser
  def self.user_create(attrs, role_ids = nil)
    populate_attributes!(attrs, role_ids: role_ids)

    if attrs[:login]
      attrs[:login] = EmailHelper::Idn.to_unicode(attrs[:login])
    end

    if (user = User.find_by('email = :email OR login = :email', attrs))
      if user.no_name? && attrs[:firstname].present?
        user.name_from_channel_import = true
        user.update!(attrs.slice(:firstname))
      end
    elsif (user = User.create!(attrs.merge(name_from_channel_import: true)))
      user.update!(updated_by_id: user.id, created_by_id: user.id)
    end

    user
  end

  def self.populate_attributes!(attrs, **extras)
    if attrs[:email].match?(%r{\S\s+\S}) || attrs[:email].match?(%r{^<|>$})
      attrs[:preferences] = { mail_delivery_failed:        true,
                              mail_delivery_failed_reason: 'invalid email',
                              mail_delivery_failed_data:   Time.zone.now }
    end

    attrs.merge!(
      email:         sanitize_email(attrs[:email]),
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
