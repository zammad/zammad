# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::StoreValue::UnknownCustomer < FormUpdater::StoreValue::Base

  # A customer who does not exist yet is the typed-in address or number. Stored bare, it could
  #   not be told from an id on the way back, as the old UI writes ids as strings too - so it is
  #   wrapped the way the create mutation takes a customer, and FormUpdater::ApplyValue::UserAutocomplete
  #   unwraps it.
  def self.wrap(value)
    return value if !value.is_a?(String) || value.blank?

    value.include?('@') ? { 'email' => value } : { 'phone' => value }
  end

  def self.unwrap(value)
    return if !value.is_a?(Hash)

    value = value.with_indifferent_access

    value[:email] || value[:phone]
  end

  def can_handle_field?(field:, value:)
    field == 'customer_id' && value.is_a?(String) && value.present?
  end

  def map_value(field:, value:)
    self.class.wrap(value)
  end
end
