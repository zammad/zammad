# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Pseudonymisation

  def self.of_hash(source)
    return if source.blank?

    source.transform_values do |value|
      of_value(value.to_s)
    end
  end

  def self.of_value(source)
    of_email_address(source)
  rescue
    of_string(source)
  end

  def self.of_email_address(source)
    email_address = Mail::AddressList.new(source).addresses.first
    "#{of_string(email_address.local)}@#{of_domain(email_address.domain)}"
  rescue
    raise ArgumentError
  end

  def self.of_domain(source)
    domain_parts = source.split('.')

    # e.g. localhost
    return of_string(source) if domain_parts.size == 1

    tld   = domain_parts[-1]
    other = domain_parts[0..-2].join('.')
    "#{of_string(other)}.#{tld}"
  end

  def self.of_string(source)
    return '*' if source.to_s.length <= 1
    return "#{source.first}*#{source.last}" if source.exclude?(' ')

    source.split.map do |sub_string|
      of_string(sub_string)
    end.join(' ')
  end
end
