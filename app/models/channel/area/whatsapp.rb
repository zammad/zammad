# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Channel::Area::Whatsapp
  extend ActiveSupport::Concern

  included do
    validate :validate_whatsapp_phone_number, if: :area_whatsapp?
  end

  private

  def validate_whatsapp_phone_number
    return if Channel
      .in_area('WhatsApp::Business')
      .then { |query| persisted? ? query.where.not(id:) : query }
      .none? { |elem| identical_whatsapp_phone_numbers?(elem, self) }

    errors.add :base, __('Phone number is already in use by another WhatsApp account.')
  end

  def identical_whatsapp_phone_numbers?(one, another)
    one_phone_number     = extract_whatsapp_phone_number(one)
    another_phone_number = extract_whatsapp_phone_number(another)

    one_phone_number && another_phone_number && one_phone_number == another_phone_number
  end

  def extract_whatsapp_phone_number(channel)
    channel.options[:phone_number_id]&.to_s&.downcase
  end

  def area_whatsapp?
    area == 'WhatsApp::Business'
  end
end
