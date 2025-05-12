# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Account::PhoneNumbers < Whatsapp::Client

  attr_reader :phone_numbers_api, :business_id

  def initialize(access_token:, business_id: nil)
    super(access_token:)

    @business_id = business_id
    @phone_numbers_api = WhatsappSdk::Api::PhoneNumbers.new client
  end

  def all
    raise ArgumentError, __("The required parameter 'business_id' is missing.") if business_id.nil?

    phone_numbers = phone_numbers_api.list(business_id.to_i).records

    return [] if phone_numbers.nil?

    phone_numbers.to_h do |phone_number|
      [
        phone_number.id,
        format('%{name} (%{number})', name: phone_number.verified_name, number: phone_number.display_phone_number),
      ]
    end
  rescue WhatsappSdk::Api::Responses::HttpResponseError => e
    handle_error(response: e)
  end

  def get(id)
    phone_number = phone_numbers_api.get(id.to_i)

    return if phone_number.nil?

    {
      name:         phone_number.verified_name,
      phone_number: phone_number.display_phone_number
    }
  rescue WhatsappSdk::Api::Responses::HttpResponseError => e
    handle_error(response: e)
  end
end
