# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::EmailRecipientNormalizer

  class << self
    def normalize(input)
      return input if input.blank?

      addresses = parse_addresses(input)
      return input if addresses.blank?

      emails = addresses.map { |a| a.address.to_s.strip.downcase }
                        .select { |e| e.include?('@') }
                        .uniq

      users = User.where(email: emails).index_by { |u| u.email.downcase }

      seen   = {}
      result = []

      addresses.each do |addr|
        normalized = normalize_address(addr, seen, users)
        result << normalized if normalized.present?
      end

      result.join(', ')
    rescue
      input
    end

    private

    def parse_addresses(input)
      Mail::AddressList.new(input).addresses
    rescue
      []
    end

    def normalize_address(addr, seen, users)
      raw = addr.address.to_s.strip
      return if raw.blank?

      unless raw.include?('@')
        return raw
      end

      email = raw.downcase

      return if seen[email]

      user = User.find_by(email: email) || users[email]

      result =
        if user.present?
          user.fullname(recipient_line: true)
        else
          display_name = addr.display_name.to_s.strip
          if display_name.present?
            Channel::EmailBuild.recipient_line(display_name, email)
          else
            email
          end
        end

      seen[email] = true
      result
    end
  end
end
