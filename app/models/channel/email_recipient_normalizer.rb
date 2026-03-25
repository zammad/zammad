# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::EmailRecipientNormalizer

  class << self
    def normalize(input)
      return input if input.blank?

      addresses = parse_addresses(input)
      return input if addresses.blank?

      emails = addresses.filter_map do |address|
        raw = address.address.to_s.strip
        raw.downcase if raw.include?('@')
      end.uniq

      users = User.where(email: emails).index_by { |user| user.email.downcase }

      seen   = {}
      result = []

      addresses.each do |address|
        normalized = normalize_address(address, seen, users)
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

    def normalize_address(address, seen, users)
      raw = address.address.to_s.strip
      return if raw.blank?
      return raw if raw.exclude?('@')

      email = raw.downcase
      return if seen[email]

      user = users[email]

      result =
        if user.present?
          user.fullname(recipient_line: true)
        else
          display_name = address.display_name.to_s.strip
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
